#include <cstring>

#include "include/ViPERParams.h"
#include "viper/ViPER.h"

#include "ViPER4WindowsAPO.h"
#include "ViPERLog.h"
#include <avrt.h>

#define VIPER_STRINGIFY2(x) #x
#define VIPER_STRINGIFY(x) VIPER_STRINGIFY2(x)

#if defined(__aarch64__) || defined(_M_ARM64)
static constexpr char kArch[] = "ARM64";
#elif defined(__arm__) || defined(_M_ARM)
static constexpr char kArch[] = "ARM";
#elif defined(__x86_64__) || defined(_M_X64) || defined(_M_AMD64)
static constexpr char kArch[] = "x86_64";
#elif defined(__i386__) || defined(_M_IX86)
static constexpr char kArch[] = "x86";
#else
static constexpr char kArch[] = "unknown";
#endif

#pragma comment(lib, "advapi32.lib")
#pragma comment(lib, "avrt.lib")

const CRegAPOProperties<1> CViPER4WindowsMFX::RegProperties(
    CLSID_ViPER4WindowsMFX,
    L"ViPER4Windows MFX",
    L"Copyright ViPER520",
    1,
    0,
    __uuidof(IAudioProcessingObject),
    static_cast<APO_FLAG>(
        APO_FLAG_SAMPLESPERFRAME_MUST_MATCH | APO_FLAG_FRAMESPERSECOND_MUST_MATCH
        | APO_FLAG_BITSPERSAMPLE_MUST_MATCH | APO_FLAG_INPLACE
    )
);

CViPER4WindowsMFX::CViPER4WindowsMFX() :
    CBaseAudioProcessingObject(RegProperties) {}

CViPER4WindowsMFX::~CViPER4WindowsMFX() {
    StopParamWatch();
    delete staged_params_.exchange(nullptr, std::memory_order_relaxed);
    delete consumed_params_.exchange(nullptr, std::memory_order_relaxed);
    CloseSharedMemory();
    ResetChild();
}

HRESULT CViPER4WindowsMFX::FinalConstruct() {
    engine_ = std::make_unique<ViPER>();
    TryOpenSharedMemory();
    StartParamWatch();
    ViPERLog(
        "[ViPER] FinalConstruct: engine=%p paramsBase=%p statusBase=%p\n",
        engine_.get(),
        params_base_,
        status_base_
    );
    return S_OK;
}

void CViPER4WindowsMFX::ResetChild() {
    if (child_cfg_) {
        child_cfg_->Release();
        child_cfg_ = nullptr;
    }
    if (child_rt_) {
        child_rt_->Release();
        child_rt_ = nullptr;
    }
    if (child_apo_) {
        child_apo_->Release();
        child_apo_ = nullptr;
    }
}

STDMETHODIMP CViPER4WindowsMFX::GetLatency(HNSTIME *pTime) {
    if (!pTime) return E_POINTER;
    *pTime = 0;
    return S_OK;
}

STDMETHODIMP CViPER4WindowsMFX::GetRegistrationProperties(APO_REG_PROPERTIES **ppRegProps
) {
    return CBaseAudioProcessingObject::GetRegistrationProperties(ppRegProps);
}

STDMETHODIMP CViPER4WindowsMFX::IsOutputFormatSupported(
    IAudioMediaType *pOppositeFormat,
    IAudioMediaType *pRequestedOutputFormat,
    IAudioMediaType **ppSupportedOutputFormat
) {
    HRESULT hr = CBaseAudioProcessingObject::IsOutputFormatSupported(
        pOppositeFormat, pRequestedOutputFormat, ppSupportedOutputFormat
    );
    if (FAILED(hr)) {
        ViPERLog("[ViPER] IsOutputFormatSupported FAILED hr=0x%08X\n", hr);
    }
    return hr;
}

STDMETHODIMP CViPER4WindowsMFX::Reset() {
    if (engine_) engine_->ResetAllEffects();
    return CBaseAudioProcessingObject::Reset();
}

STDMETHODIMP CViPER4WindowsMFX::Initialize(UINT32 cbDataSize, BYTE *pbyData) {
    if (cbDataSize == 0 && pbyData == nullptr) {
        return CBaseAudioProcessingObject::Initialize(cbDataSize, pbyData);
    }
    if (pbyData == nullptr) {
        ViPERLog("[ViPER] Initialize: pbyData is null but cbDataSize=%u\n", cbDataSize);
        return E_POINTER;
    }

    HRESULT hr;
    if (cbDataSize >= sizeof(APOInitSystemEffects2)) {
        auto *p = reinterpret_cast<APOInitSystemEffects2 *>(pbyData);
        hr = CBaseAudioProcessingObject::Initialize(
            sizeof(APOInitBaseStruct), reinterpret_cast<BYTE *>(&p->APOInit)
        );
    } else if (cbDataSize >= sizeof(APOInitSystemEffects)) {
        auto *p = reinterpret_cast<APOInitSystemEffects *>(pbyData);
        hr = CBaseAudioProcessingObject::Initialize(
            sizeof(APOInitBaseStruct), reinterpret_cast<BYTE *>(&p->APOInit)
        );
    } else {
        hr = CBaseAudioProcessingObject::Initialize(cbDataSize, pbyData);
    }
    if (FAILED(hr)) {
        ViPERLog("[ViPER] Initialize FAILED hr=0x%08X cbDataSize=%u\n", hr, cbDataSize);
        return hr;
    }

    ResetChild();
    endpoint_id_[0] = L'\0';

    if (cbDataSize >= sizeof(APOInitSystemEffects2)) {
        auto *p_sys_fx2 = reinterpret_cast<APOInitSystemEffects2 *>(pbyData);
        if (p_sys_fx2->pAPOEndpointProperties) {
            PROPVARIANT var;
            PropVariantInit(&var);
            PROPERTYKEY pkGuid = {
                {0x1da5d803,
                 0xd492,
                 0x4edd,
                 {0x8c, 0x23, 0xe0, 0xc0, 0xff, 0xee, 0x7f, 0x0e}},
                4
            };
            if (SUCCEEDED(p_sys_fx2->pAPOEndpointProperties->GetValue(pkGuid, &var))
                && var.vt == VT_LPWSTR && var.pwszVal) {
                wcsncpy_s(endpoint_id_, var.pwszVal, _TRUNCATE);
            }
            PropVariantClear(&var);
        }
    } else if (cbDataSize >= sizeof(APOInitSystemEffects)) {
        auto *p_sys_fx = reinterpret_cast<APOInitSystemEffects *>(pbyData);
        if (p_sys_fx->pAPOEndpointProperties) {
            PROPVARIANT var;
            PropVariantInit(&var);
            PROPERTYKEY pkGuid = {
                {0x1da5d803,
                 0xd492,
                 0x4edd,
                 {0x8c, 0x23, 0xe0, 0xc0, 0xff, 0xee, 0x7f, 0x0e}},
                4
            };
            if (SUCCEEDED(p_sys_fx->pAPOEndpointProperties->GetValue(pkGuid, &var))
                && var.vt == VT_LPWSTR && var.pwszVal) {
                wcsncpy_s(endpoint_id_, var.pwszVal, _TRUNCATE);
            }
            PropVariantClear(&var);
        }
    }

    HKEY hKey = nullptr;
    wchar_t childClsidStr[128] = {};
    DWORD cb_data = sizeof(childClsidStr);
    LONG res =
        RegOpenKeyExW(HKEY_LOCAL_MACHINE, L"SOFTWARE\\ViPER4Windows", 0, KEY_READ, &hKey);
    if (res == ERROR_SUCCESS) {
        if (endpoint_id_[0] != L'\0') {
            wchar_t keyName[128];
            swprintf_s(keyName, L"OrigCompMFX_%ls", endpoint_id_);
            res = RegQueryValueExW(
                hKey,
                keyName,
                nullptr,
                nullptr,
                reinterpret_cast<BYTE *>(childClsidStr),
                &cb_data
            );
            if (res != ERROR_SUCCESS || childClsidStr[0] == L'\0') {
                cb_data = sizeof(childClsidStr);
                memset(childClsidStr, 0, sizeof(childClsidStr));
                swprintf_s(keyName, L"OrigSFX_%ls", endpoint_id_);
                res = RegQueryValueExW(
                    hKey,
                    keyName,
                    nullptr,
                    nullptr,
                    reinterpret_cast<BYTE *>(childClsidStr),
                    &cb_data
                );
            }
        }
        if (res != ERROR_SUCCESS || childClsidStr[0] == L'\0') {
            cb_data = sizeof(childClsidStr);
            memset(childClsidStr, 0, sizeof(childClsidStr));
            res = RegQueryValueExW(
                hKey,
                L"OriginalCompMFX",
                nullptr,
                nullptr,
                reinterpret_cast<BYTE *>(childClsidStr),
                &cb_data
            );
        }
        if (res != ERROR_SUCCESS || childClsidStr[0] == L'\0') {
            cb_data = sizeof(childClsidStr);
            memset(childClsidStr, 0, sizeof(childClsidStr));
            res = RegQueryValueExW(
                hKey,
                L"OriginalSFX",
                nullptr,
                nullptr,
                reinterpret_cast<BYTE *>(childClsidStr),
                &cb_data
            );
        }
        RegCloseKey(hKey);
    }

    if (res == ERROR_SUCCESS && childClsidStr[0] != L'\0') {
        GUID childGuid;
        HRESULT hr_child = CLSIDFromString(childClsidStr, &childGuid);
        if (SUCCEEDED(hr_child)) {
            hr_child = CoCreateInstance(
                childGuid,
                nullptr,
                CLSCTX_INPROC_SERVER,
                __uuidof(IAudioProcessingObject),
                reinterpret_cast<void **>(&child_apo_)
            );
            if (SUCCEEDED(hr_child)) {
                hr_child = child_apo_->QueryInterface(
                    __uuidof(IAudioProcessingObjectRT),
                    reinterpret_cast<void **>(&child_rt_)
                );
                if (FAILED(hr_child)) {
                    ViPERLog("[ViPER] Child QI for RT failed hr=0x%08X\n", hr_child);
                    ResetChild();
                }
            }
            if (child_apo_) {
                hr_child = child_apo_->QueryInterface(
                    __uuidof(IAudioProcessingObjectConfiguration),
                    reinterpret_cast<void **>(&child_cfg_)
                );
                if (FAILED(hr_child)) {
                    ViPERLog("[ViPER] Child QI for Config failed hr=0x%08X\n", hr_child);
                    ResetChild();
                }
            }
            if (child_apo_) {
                hr_child = child_apo_->Initialize(cbDataSize, pbyData);
                if (FAILED(hr_child)) {
                    ViPERLog("[ViPER] Child Initialize failed hr=0x%08X\n", hr_child);
                    ResetChild();
                }
            }
        } else {
            ViPERLog("[ViPER] CLSIDFromString failed for child hr=0x%08X\n", hr_child);
        }
    }

    return S_OK;
}

STDMETHODIMP CViPER4WindowsMFX::IsInputFormatSupported(
    IAudioMediaType *pOppositeFormat,
    IAudioMediaType *pRequestedInputFormat,
    IAudioMediaType **ppSupportedInputFormat
) {
    if (!pRequestedInputFormat || !ppSupportedInputFormat) return E_POINTER;

    HRESULT hr;
    if (child_apo_) {
        hr = child_apo_->IsInputFormatSupported(
            pOppositeFormat, pRequestedInputFormat, ppSupportedInputFormat
        );
        if (SUCCEEDED(hr)) return hr;
    }
    hr = CBaseAudioProcessingObject::IsInputFormatSupported(
        pOppositeFormat, pRequestedInputFormat, ppSupportedInputFormat
    );
    if (FAILED(hr)) {
        ViPERLog("[ViPER] IsInputFormatSupported FAILED hr=0x%08X\n", hr);
    }
    return hr;
}

STDMETHODIMP CViPER4WindowsMFX::LockForProcess(
    UINT32 u32NumInputConnections,
    APO_CONNECTION_DESCRIPTOR **ppInputConnections,
    UINT32 u32NumOutputConnections,
    APO_CONNECTION_DESCRIPTOR **ppOutputConnections
) {
    ViPERLog(
        "[ViPER] LockForProcess called (this=%p), inputs=%u outputs=%u\n",
        this,
        u32NumInputConnections,
        u32NumOutputConnections
    );

    if (child_cfg_) {
        HRESULT hr_child = child_cfg_->LockForProcess(
            u32NumInputConnections,
            ppInputConnections,
            u32NumOutputConnections,
            ppOutputConnections
        );
        ViPERLog("[ViPER] Child LockForProcess hr=0x%08X\n", hr_child);
    }

    HRESULT hr = CBaseAudioProcessingObject::LockForProcess(
        u32NumInputConnections,
        ppInputConnections,
        u32NumOutputConnections,
        ppOutputConnections
    );
    if (FAILED(hr)) {
        ViPERLog("[ViPER] LockForProcess: base FAILED hr=0x%08X\n", hr);
        return hr;
    }

    UNCOMPRESSEDAUDIOFORMAT format;
    hr = ppInputConnections[0]->pFormat->GetUncompressedAudioFormat(&format);
    if (SUCCEEDED(hr)) {
        channel_count_ = format.dwSamplesPerFrame;
        sample_rate_ = static_cast<UINT32>(format.fFramesPerSecond);
    }
    if (channel_count_ == 0) channel_count_ = 2;
    max_frames_ = ppInputConnections[0]->u32MaxFrameCount;

    if (engine_) {
        engine_->SetSamplingRate(sample_rate_);
        engine_->ResetAllEffects();
        process_buffer_.resize(max_frames_ * channel_count_);
        ViPERLog(
            "[ViPER] Engine configured: rate=%u buffer=%zu\n",
            sample_rate_,
            process_buffer_.size()
        );
    }

    WriteStatusShm();

    ViPERLog(
        "[ViPER] LockForProcess (this=%p): SUCCESS ch=%u rate=%u maxFrames=%u\n",
        this,
        channel_count_,
        sample_rate_,
        max_frames_
    );
    return S_OK;
}

STDMETHODIMP CViPER4WindowsMFX::UnlockForProcess() {
    ViPERLog("[ViPER] UnlockForProcess called (this=%p)\n", this);
    if (child_cfg_) {
        child_cfg_->UnlockForProcess();
    }
    return CBaseAudioProcessingObject::UnlockForProcess();
}

#pragma AVRT_CODE_BEGIN
STDMETHODIMP_(void)
CViPER4WindowsMFX::APOProcess(
    UINT32 u32NumInputConnections,
    APO_CONNECTION_PROPERTY **ppInputConnections,
    UINT32 u32NumOutputConnections,
    APO_CONNECTION_PROPERTY **ppOutputConnections
) {
    if (u32NumInputConnections == 0 || u32NumOutputConnections == 0
        || ppInputConnections == nullptr || ppOutputConnections == nullptr
        || ppInputConnections[0] == nullptr || ppOutputConnections[0] == nullptr) {
        return;
    }

    static unsigned apoProcessCount = 0;
    if (apoProcessCount < 10) {
        float *pIn = reinterpret_cast<float *>(ppInputConnections[0]->pBuffer);
        float *pOut = reinterpret_cast<float *>(ppOutputConnections[0]->pBuffer);
        ViPERLog(
            "[ViPER] APOProcess #%u: flags=%u frames=%u inplace=%s child=%p in[0]=%.6f\n",
            apoProcessCount,
            ppInputConnections[0]->u32BufferFlags,
            ppInputConnections[0]->u32ValidFrameCount,
            (pIn == pOut) ? "YES" : "NO",
            child_rt_,
            (ppInputConnections[0]->u32ValidFrameCount > 0 && pIn) ? pIn[0] : 0.0f
        );
    }
    apoProcessCount++;

    if ((apoProcessCount & 0x3F) == 0) {
        WriteStatusShm();
    }

    if (child_rt_) {
        child_rt_->APOProcess(
            u32NumInputConnections,
            ppInputConnections,
            u32NumOutputConnections,
            ppOutputConnections
        );
    }

    switch (ppInputConnections[0]->u32BufferFlags) {
        case BUFFER_VALID:
        case BUFFER_SILENT: {
            float *pInput = reinterpret_cast<float *>(ppInputConnections[0]->pBuffer);
            float *pOutput = reinterpret_cast<float *>(ppOutputConnections[0]->pBuffer);
            UINT32 frame_count = ppInputConnections[0]->u32ValidFrameCount;

            if (ppInputConnections[0]->u32BufferFlags == BUFFER_SILENT) {
                memset(pInput, 0, frame_count * channel_count_ * sizeof(float));
            }

            if (!child_rt_ && pOutput != pInput) {
                memcpy(pOutput, pInput, frame_count * channel_count_ * sizeof(float));
            }

            if (staged_master_off_.exchange(false, std::memory_order_acquire)) {
                std::lock_guard<std::mutex> g(engine_lock_);
                engine_->ResetAllEffects();
            }
            auto *pending = staged_params_.exchange(nullptr, std::memory_order_acquire);
            if (pending) {
                std::lock_guard<std::mutex> g(engine_lock_);
                ApplyParamsToEngine(*pending);
                auto *prev =
                    consumed_params_.exchange(pending, std::memory_order_relaxed);
                (void) prev;
            }

            bool master_on = master_enabled_.load(std::memory_order_relaxed);
            if (engine_ && frame_count > 0 && master_on) {
                UINT32 total_samples = frame_count * channel_count_;
                if (process_buffer_.size() < total_samples) {
                    process_buffer_.resize(total_samples);
                }
                memcpy(process_buffer_.data(), pOutput, total_samples * sizeof(float));
                float beforeSample = process_buffer_[0];
                {
                    std::lock_guard<std::mutex> g(engine_lock_);
                    engine_->Process(process_buffer_, frame_count);
                }
                float afterSample = process_buffer_[0];
                if (apoProcessCount < 15) {
                    ViPERLog(
                        "[ViPER] Engine: before=%.6f after=%.6f delta=%.6f scale=%.3f\n",
                        beforeSample,
                        afterSample,
                        afterSample - beforeSample,
                        (beforeSample != 0.0f) ? afterSample / beforeSample : 0.0f
                    );
                }
                memcpy(pOutput, process_buffer_.data(), total_samples * sizeof(float));
            }

            ppOutputConnections[0]->u32ValidFrameCount = frame_count;
            ppOutputConnections[0]->u32BufferFlags = BUFFER_VALID;
            break;
        }
        default:
            break;
    }
}
#pragma AVRT_CODE_END

void CViPER4WindowsMFX::TryOpenSharedMemory() {
    ULONGLONG now = GetTickCount64();
    if (last_shm_attempt_ != 0 && (now - last_shm_attempt_) < 1000) return;
    last_shm_attempt_ = now;

    if (!params_base_) {
        params_map_ = OpenFileMappingW(FILE_MAP_READ, FALSE, VIPER_PARAMS_SHM_NAME);
        if (params_map_) {
            params_base_ = static_cast<uint8_t *>(
                MapViewOfFile(params_map_, FILE_MAP_READ, 0, 0, VIPER_PARAMS_SHM_SIZE)
            );
            if (!params_base_) {
                ViPERLog(
                    "[ViPER] shm_params MapViewOfFile FAILED err=%lu\n", GetLastError()
                );
                CloseHandle(params_map_);
                params_map_ = nullptr;
            } else {
                last_update_count_ = UINT32_MAX;
                ViPERLog("[ViPER] shm_params OPENED base=%p\n", params_base_);
            }
        }
    }

    if (!status_base_) {
        status_map_ = OpenFileMappingW(
            FILE_MAP_READ | FILE_MAP_WRITE, FALSE, VIPER_STATUS_SHM_NAME
        );
        if (status_map_) {
            status_base_ = static_cast<uint8_t *>(MapViewOfFile(
                status_map_, FILE_MAP_READ | FILE_MAP_WRITE, 0, 0, VIPER_STATUS_SHM_SIZE
            ));
            if (!status_base_) {
                ViPERLog(
                    "[ViPER] shm_status MapViewOfFile FAILED err=%lu\n", GetLastError()
                );
                CloseHandle(status_map_);
                status_map_ = nullptr;
            } else {
                ViPERLog("[ViPER] shm_status OPENED base=%p\n", status_base_);
                WriteStatusShm();
            }
        }
    }

    if (!param_event_) {
        param_event_ = OpenEventW(SYNCHRONIZE, FALSE, VIPER_EVENT_NAME);
    }
    if (!bulk_map_file_) {
        bulk_map_file_ = OpenFileMappingW(FILE_MAP_READ, FALSE, VIPER_BULK_SHM_NAME);
        if (bulk_map_file_) {
            bulk_data_ =
                MapViewOfFile(bulk_map_file_, FILE_MAP_READ, 0, 0, VIPER_BULK_SHM_SIZE);
        }
    }
    if (!bulk_event_) {
        bulk_event_ = OpenEventW(SYNCHRONIZE, FALSE, VIPER_BULK_EVENT_NAME);
    }
}

void CViPER4WindowsMFX::CloseSharedMemory() {
    if (params_base_) {
        UnmapViewOfFile(params_base_);
        params_base_ = nullptr;
    }
    if (params_map_) {
        CloseHandle(params_map_);
        params_map_ = nullptr;
    }
    if (status_base_) {
        UnmapViewOfFile(status_base_);
        status_base_ = nullptr;
    }
    if (status_map_) {
        CloseHandle(status_map_);
        status_map_ = nullptr;
    }
    if (param_event_) {
        CloseHandle(param_event_);
        param_event_ = nullptr;
    }
    if (bulk_data_) {
        UnmapViewOfFile(bulk_data_);
        bulk_data_ = nullptr;
    }
    if (bulk_map_file_) {
        CloseHandle(bulk_map_file_);
        bulk_map_file_ = nullptr;
    }
    if (bulk_event_) {
        CloseHandle(bulk_event_);
        bulk_event_ = nullptr;
    }
}

void CViPER4WindowsMFX::WriteStatusShm() {
    if (!status_base_) return;
    auto *s = reinterpret_cast<V4WStatus *>(status_base_);
    if (s->magic != VIPER_SHM_MAGIC || s->version != VIPER_FORMAT_VERSION) {
        memset(s, 0, sizeof(V4WStatus));
        s->magic = VIPER_SHM_MAGIC;
        s->version = VIPER_FORMAT_VERSION;
    }
    s->enabled = 1;
    s->configured = engine_ ? 1 : 0;
    s->sample_rate = sample_rate_;
    s->processedFrames = engine_ ? engine_->GetProcessedFrames() : 0;
    snprintf(
        s->version_name,
        sizeof(s->version_name),
        "%s(%s)",
        VERSION_NAME,
        VIPER_STRINGIFY(VERSION_CODE)
    );
    strncpy_s(s->arch_string, sizeof(s->arch_string), kArch, _TRUNCATE);
    status_seq_++;
    InterlockedExchange(
        reinterpret_cast<volatile LONG *>(&s->status_seq), static_cast<LONG>(status_seq_)
    );
}

void CViPER4WindowsMFX::StartParamWatch() {
    shutdown_event_ = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    watch_thread_ = CreateThread(nullptr, 0, ParamWatchThread, this, 0, nullptr);
}

void CViPER4WindowsMFX::StopParamWatch() {
    if (shutdown_event_) {
        SetEvent(shutdown_event_);
    }
    if (watch_thread_) {
        WaitForSingleObject(watch_thread_, 2000);
        CloseHandle(watch_thread_);
        watch_thread_ = nullptr;
    }
    if (shutdown_event_) {
        CloseHandle(shutdown_event_);
        shutdown_event_ = nullptr;
    }
}

unsigned long __stdcall CViPER4WindowsMFX::ParamWatchThread(void *parameter) {
    auto *self = static_cast<CViPER4WindowsMFX *>(parameter);

    DWORD mmcss_task_index = 0;
    HANDLE mmcss_handle = AvSetMmThreadCharacteristicsW(L"Audio", &mmcss_task_index);
    if (!mmcss_handle) {
        ViPERLog("[ViPER] AvSetMmThreadCharacteristics failed err=%lu\n", GetLastError());
    }

    while (true) {
        self->TryOpenSharedMemory();

        self->CheckAndApplyParams();
        self->CheckAndReloadBulk(
            kBulkDdcBase, kBulkDdcRegionSize, self->last_bulk_ddc_seq_
        );
        self->CheckAndReloadBulk(
            kBulkConvolverBase, kBulkConvolverRegionSize, self->last_bulk_convolver_seq_
        );

        HANDLE handles[3] = {self->shutdown_event_, nullptr, nullptr};
        DWORD handle_count = 1;
        if (self->param_event_) {
            handles[handle_count++] = self->param_event_;
        }
        if (self->bulk_event_) {
            handles[handle_count++] = self->bulk_event_;
        }

        DWORD timeout = (handle_count > 1) ? INFINITE : 1000;
        DWORD result = WaitForMultipleObjects(handle_count, handles, FALSE, timeout);
        if (result == WAIT_OBJECT_0) break;

        if (handle_count == 3 && result == WAIT_OBJECT_0 + 2) {
            self->CheckAndReloadBulk(
                kBulkDdcBase, kBulkDdcRegionSize, self->last_bulk_ddc_seq_
            );
            self->CheckAndReloadBulk(
                kBulkConvolverBase,
                kBulkConvolverRegionSize,
                self->last_bulk_convolver_seq_
            );
        }

        self->CheckAndApplyParams();
    }

    if (mmcss_handle) {
        AvRevertMmThreadCharacteristics(mmcss_handle);
    }
    return 0;
}

void CViPER4WindowsMFX::CheckAndApplyParams() {
    if (!params_base_) return;

    auto *hdr = reinterpret_cast<volatile V4WHeader *>(params_base_);
    if (hdr->magic != VIPER_SHM_MAGIC || hdr->version != VIPER_FORMAT_VERSION) {
        return;
    }

    uint32_t update_count = hdr->update_count;
    if (update_count == last_update_count_) return;
    MemoryBarrier();

    uint32_t active_index = hdr->active_index;
    uint32_t slot_off = (active_index == 0) ? kV4WSlotAOffset : kV4WSlotBOffset;

    viper::ViPERParams snapshot;
    memcpy(&snapshot, params_base_ + slot_off, sizeof(viper::ViPERParams));

    master_enabled_.store(hdr->master_enabled != 0, std::memory_order_relaxed);

    delete consumed_params_.exchange(nullptr, std::memory_order_relaxed);

    if (hdr->master_enabled) {
        auto *staged = new viper::ViPERParams(snapshot);
        auto *prev = staged_params_.exchange(staged, std::memory_order_release);
        delete prev;
    } else {
        staged_master_off_.store(true, std::memory_order_release);
    }

    last_update_count_ = update_count;
    WriteStatusShm();
}

bool CViPER4WindowsMFX::CheckAndReloadBulk(
    uint32_t base, uint32_t region_size, uint32_t &last_seq
) {
    if (!bulk_data_) return false;

    auto *bulk_base = static_cast<const uint8_t *>(bulk_data_) + base;
    auto *hdr = reinterpret_cast<volatile const ViPERBulkHeader *>(bulk_base);

    uint32_t seq = hdr->seq;
    if (seq == last_seq) return false;
    MemoryBarrier();

    ViPERBulkHeader hdr_copy;
    memcpy(&hdr_copy, bulk_base, sizeof(ViPERBulkHeader));
    MemoryBarrier();
    if (hdr->seq != seq) return false;

    DispatchBulk(hdr_copy, bulk_base + sizeof(ViPERBulkHeader), region_size);
    last_seq = seq;
    return true;
}

void CViPER4WindowsMFX::DispatchBulk(
    const ViPERBulkHeader &hdr, const uint8_t *payload, uint32_t region_size
) {
    if (hdr.magic != VIPER_SHM_MAGIC || hdr.version != VIPER_FORMAT_VERSION) {
        ViPERLog(
            "[ViPER] DispatchBulk: bad header magic=%08X version=%u",
            hdr.magic,
            hdr.version
        );
        return;
    }
    if (hdr.data_size > region_size - sizeof(ViPERBulkHeader)) {
        ViPERLog("[ViPER] DispatchBulk: payload %u exceeds region", hdr.data_size);
        return;
    }

    std::lock_guard<std::mutex> g(engine_lock_);
    if (!engine_) return;

    switch (hdr.command) {
        case VIPER_BULK_CMD_DDC: {
            const uint32_t section_count = hdr.arg1;
            const uint32_t expected = section_count * sizeof(viper::BiquadSection) * 2;
            if (hdr.data_size != expected) {
                ViPERLog(
                    "[ViPER] DDC: dataSize %u != expected %u "
                    "(section_count=%u)",
                    hdr.data_size,
                    expected,
                    section_count
                );
                break;
            }
            const auto *sec44100 =
                reinterpret_cast<const viper::BiquadSection *>(payload);
            const auto *sec48000 = sec44100 + section_count;
            engine_->LoadDdcCoefficients(sec44100, sec48000, section_count);
            ViPERLog("[ViPER] DDC load: section_count=%u OK", section_count);
            break;
        }
        case VIPER_BULK_CMD_CONVOLVER_KERNEL: {
            const uint32_t frame_count = hdr.arg1;
            const uint32_t channels = hdr.arg2;
            const uint32_t kernel_id = hdr.arg3;
            const uint32_t expected = frame_count * channels * sizeof(float);
            if (hdr.data_size != expected) {
                ViPERLog(
                    "[ViPER] Convolver: dataSize %u != expected %u "
                    "(frame_count=%u ch=%u)",
                    hdr.data_size,
                    expected,
                    frame_count,
                    channels
                );
                break;
            }
            const auto *samples = reinterpret_cast<const float *>(payload);
            const auto resolved_id =
                engine_->LoadConvolverKernel(samples, frame_count, channels, kernel_id);
            ViPERLog(
                "[ViPER] Convolver load: frames=%u ch=%u kernel_id=%u %s",
                frame_count,
                channels,
                kernel_id,
                resolved_id.has_value() ? "OK" : "FAILED"
            );
            break;
        }
        default:
            ViPERLog("[ViPER] DispatchBulk: unknown command %u", hdr.command);
            break;
    }
}

void CViPER4WindowsMFX::ApplyParamsToEngine(const viper::ViPERParams &params) {
    if (!engine_) return;
    engine_->ApplyParams(params);
}
