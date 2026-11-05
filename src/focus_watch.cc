#include "focus_watch.h"

#include <windows.h>
#include <uiautomation.h>
#include <wrl/client.h>

#include <atomic>

#include "utils.h"

namespace {

std::atomic<bool> g_editable{false};
std::atomic<bool> g_ready{false};

bool IsEditableElement(IUIAutomationElement* element) {
  if (!element) {
    return false;
  }
  CONTROLTYPEID type = 0;
  if (FAILED(element->get_CurrentControlType(&type))) {
    return false;
  }
  if (type == UIA_EditControlTypeId) {
    return true;
  }
  // Some edit controls (e.g. spin/combo edits) surface as ComboBox.
  if (type == UIA_ComboBoxControlTypeId) {
    return true;
  }
  return false;
}

class FocusChangedHandler final : public IUIAutomationFocusChangedEventHandler {
 public:
  ULONG STDMETHODCALLTYPE AddRef() override { return 2; }
  ULONG STDMETHODCALLTYPE Release() override { return 1; }

  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID riid, void** ppv) override {
    if (!ppv) {
      return E_POINTER;
    }
    if (riid == IID_IUnknown ||
        riid == IID_IUIAutomationFocusChangedEventHandler) {
      *ppv = static_cast<IUIAutomationFocusChangedEventHandler*>(this);
      AddRef();
      return S_OK;
    }
    *ppv = nullptr;
    return E_NOINTERFACE;
  }

  HRESULT STDMETHODCALLTYPE HandleFocusChangedEvent(
      IUIAutomationElement* sender) override {
    const bool editable = IsEditableElement(sender);
    g_editable.store(editable);
    CONTROLTYPEID type = 0;
    if (sender) {
      sender->get_CurrentControlType(&type);
    }
    DebugLog(L"FocusWatch: focus changed type={} editable={}", type, editable);
    return S_OK;
  }
};

DWORD WINAPI FocusWatchThread(LPVOID) {
  const HRESULT hr = ::CoInitializeEx(nullptr, COINIT_MULTITHREADED);
  if (FAILED(hr) && hr != RPC_E_CHANGED_MODE) {
    DebugLog(L"FocusWatch: CoInitializeEx failed {}", hr);
    return 0;
  }

  Microsoft::WRL::ComPtr<IUIAutomation> automation;
  const HRESULT create = ::CoCreateInstance(
      CLSID_CUIAutomation, nullptr, CLSCTX_INPROC_SERVER,
      IID_PPV_ARGS(automation.GetAddressOf()));
  if (FAILED(create) || !automation) {
    DebugLog(L"FocusWatch: CoCreateInstance failed {}", create);
    return 0;
  }

  auto* handler = new FocusChangedHandler();
  const HRESULT reg = automation->AddFocusChangedEventHandler(nullptr, handler);
  if (FAILED(reg)) {
    DebugLog(L"FocusWatch: AddFocusChangedEventHandler failed {}", reg);
    return 0;
  }

  Microsoft::WRL::ComPtr<IUIAutomationElement> focused;
  if (SUCCEEDED(automation->GetFocusedElement(focused.GetAddressOf())) &&
      focused) {
    g_editable.store(IsEditableElement(focused.Get()));
    CONTROLTYPEID initial_type = 0;
    focused->get_CurrentControlType(&initial_type);
    DebugLog(L"FocusWatch: initial focus type={} editable={}", initial_type,
             g_editable.load());
  }

  g_ready.store(true);
  DebugLog(L"FocusWatch: ready, editable={}", g_editable.load());

  // Keep the automation object and the handler alive for the process lifetime.
  while (true) {
    ::Sleep(5000);
  }
  return 0;
}

}  // namespace

void StartFocusWatch() {
  static bool started = false;
  if (started) {
    return;
  }
  started = true;
  ::CreateThread(nullptr, 0, FocusWatchThread, nullptr, 0, nullptr);
}

bool IsEditableFocused() {
  if (!g_ready.load()) {
    // UIA is not up yet: prefer not to swallow typed characters.
    return true;
  }
  return g_editable.load();
}