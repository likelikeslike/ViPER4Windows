
#include <chrono>
#include <cstring>

#include "include/ViPERParams.h"
#include "viper/ViPER.h"

#include "ViPER4WindowsAPO.h"
#include "ViPERLog.h"

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

#define PARAM_FX_TYPE_SWITCH 0x10003

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
    CBaseAudioProcessingObject(RegProperties) {
    ViPERLog("[ViPER] Constructor called (this=%p)\n", this);
}

CViPER4WindowsMFX::~CViPER4WindowsMFX() {
    ViPERLog("[ViPER] Destructor called (this=%p)\n", this);
    StopParamWatch();
    CloseSharedMemory();
    ResetChild();
}

HRESULT CViPER4WindowsMFX::FinalConstruct() {
    ViPERLog("[ViPER] FinalConstruct called (this=%p)\n", this);
    mEngine = std::make_unique<ViPER>();
    TryOpenSharedMemory();
    StartParamWatch();
    ViPERLog("[ViPER] FinalConstruct: engine=%p shm=%p\n", mEngine.get(), mSharedParams);
    return S_OK;
}

void CViPER4WindowsMFX::ResetChild() {
    if (mChildCfg) {
        mChildCfg->Release();
        mChildCfg = nullptr;
    }
    if (mChildRT) {
        mChildRT->Release();
        mChildRT = nullptr;
    }
    if (mChildAPO) {
        mChildAPO->Release();
        mChildAPO = nullptr;
    }
}

STDMETHODIMP CViPER4WindowsMFX::GetLatency(HNSTIME *pTime) {
    if (!pTime) return E_POINTER;
    *pTime = 0;
    return S_OK;
}

STDMETHODIMP CViPER4WindowsMFX::Initialize(UINT32 cbDataSize, BYTE *pbyData) {
    ViPERLog("[ViPER] Initialize called (this=%p), cbDataSize=%u\n", this, cbDataSize);
    ViPERLog(
        "[ViPER] sizeof APOInitBaseStruct=%u, APOInitSystemEffects=%u, "
        "APOInitSystemEffects2=%u\n",
        (UINT32) sizeof(APOInitBaseStruct),
        (UINT32) sizeof(APOInitSystemEffects),
        (UINT32) sizeof(APOInitSystemEffects2)
    );

    if (cbDataSize == 0 && pbyData == nullptr) {
        ViPERLog("[ViPER] Initialize: null init, calling base with 0/null\n");
        HRESULT hr = CBaseAudioProcessingObject::Initialize(cbDataSize, pbyData);
        ViPERLog("[ViPER] Initialize: base returned hr=0x%08X\n", hr);
        return hr;
    }

    if (pbyData == nullptr) {
        ViPERLog("[ViPER] Initialize: pbyData is null but cbDataSize=%u\n", cbDataSize);
        return E_POINTER;
    }

    if (cbDataSize >= sizeof(APOInitSystemEffects2)) {
        APOInitSystemEffects2 *pSysFx2 =
            reinterpret_cast<APOInitSystemEffects2 *>(pbyData);
        ViPERLog(
            "[ViPER] Initialize: got APOInitSystemEffects2, calling base with base "
            "struct size\n"
        );
        HRESULT hr = CBaseAudioProcessingObject::Initialize(
            sizeof(APOInitBaseStruct), reinterpret_cast<BYTE *>(&pSysFx2->APOInit)
        );
        if (FAILED(hr)) {
            ViPERLog("[ViPER] Initialize: base init FAILED hr=0x%08X\n", hr);
            return hr;
        }
    } else if (cbDataSize >= sizeof(APOInitSystemEffects)) {
        APOInitSystemEffects *pSysFx = reinterpret_cast<APOInitSystemEffects *>(pbyData);
        ViPERLog(
            "[ViPER] Initialize: got APOInitSystemEffects, calling base with base struct "
            "size\n"
        );
        HRESULT hr = CBaseAudioProcessingObject::Initialize(
            sizeof(APOInitBaseStruct), reinterpret_cast<BYTE *>(&pSysFx->APOInit)
        );
        if (FAILED(hr)) {
            ViPERLog("[ViPER] Initialize: base init FAILED hr=0x%08X\n", hr);
            return hr;
        }
    } else if (cbDataSize >= sizeof(APOInitBaseStruct)) {
        ViPERLog("[ViPER] Initialize: got APOInitBaseStruct, passing directly\n");
        HRESULT hr = CBaseAudioProcessingObject::Initialize(cbDataSize, pbyData);
        if (FAILED(hr)) {
            ViPERLog("[ViPER] Initialize: base init FAILED hr=0x%08X\n", hr);
            return hr;
        }
    } else {
        ViPERLog(
            "[ViPER] Initialize: unknown cbDataSize=%u, trying base anyway\n", cbDataSize
        );
        HRESULT hr = CBaseAudioProcessingObject::Initialize(cbDataSize, pbyData);
        if (FAILED(hr)) {
            ViPERLog("[ViPER] Initialize: base init FAILED hr=0x%08X\n", hr);
            return hr;
        }
    }

    ResetChild();

    HKEY hKey = nullptr;
    wchar_t childClsidStr[128] = {};
    DWORD cbData = sizeof(childClsidStr);
    LONG res =
        RegOpenKeyExW(HKEY_LOCAL_MACHINE, L"SOFTWARE\\ViPER4Windows", 0, KEY_READ, &hKey);
    if (res == ERROR_SUCCESS) {
        res = RegQueryValueExW(
            hKey,
            L"OriginalCompMFX",
            nullptr,
            nullptr,
            reinterpret_cast<BYTE *>(childClsidStr),
            &cbData
        );
        if (res != ERROR_SUCCESS || childClsidStr[0] == L'\0') {
            cbData = sizeof(childClsidStr);
            memset(childClsidStr, 0, sizeof(childClsidStr));
            res = RegQueryValueExW(
                hKey,
                L"OriginalSFX",
                nullptr,
                nullptr,
                reinterpret_cast<BYTE *>(childClsidStr),
                &cbData
            );
        }
        if (res != ERROR_SUCCESS || childClsidStr[0] == L'\0') {
            cbData = sizeof(childClsidStr);
            memset(childClsidStr, 0, sizeof(childClsidStr));
            res = RegQueryValueExW(
                hKey,
                L"OriginalCompSFX",
                nullptr,
                nullptr,
                reinterpret_cast<BYTE *>(childClsidStr),
                &cbData
            );
        }
        RegCloseKey(hKey);
    }

    if (res == ERROR_SUCCESS && childClsidStr[0] != L'\0') {
        ViPERLog("[ViPER] Child APO CLSID from registry: %ls\n", childClsidStr);
        GUID childGuid;
        HRESULT hrChild = CLSIDFromString(childClsidStr, &childGuid);
        if (SUCCEEDED(hrChild)) {
            hrChild = CoCreateInstance(
                childGuid,
                nullptr,
                CLSCTX_INPROC_SERVER,
                __uuidof(IAudioProcessingObject),
                reinterpret_cast<void **>(&mChildAPO)
            );
            if (SUCCEEDED(hrChild)) {
                hrChild = mChildAPO->QueryInterface(
                    __uuidof(IAudioProcessingObjectRT),
                    reinterpret_cast<void **>(&mChildRT)
                );
                if (FAILED(hrChild)) {
                    ViPERLog("[ViPER] Child QI for RT failed hr=0x%08X\n", hrChild);
                    ResetChild();
                }
            }
            if (mChildAPO) {
                hrChild = mChildAPO->QueryInterface(
                    __uuidof(IAudioProcessingObjectConfiguration),
                    reinterpret_cast<void **>(&mChildCfg)
                );
                if (FAILED(hrChild)) {
                    ViPERLog("[ViPER] Child QI for Config failed hr=0x%08X\n", hrChild);
                    ResetChild();
                }
            }
            if (mChildAPO) {
                hrChild = mChildAPO->Initialize(cbDataSize, pbyData);
                if (FAILED(hrChild)) {
                    ViPERLog("[ViPER] Child Initialize failed hr=0x%08X\n", hrChild);
                    ResetChild();
                } else {
                    ViPERLog("[ViPER] Child APO created and initialized OK\n");
                }
            }
        } else {
            ViPERLog("[ViPER] CLSIDFromString failed for child hr=0x%08X\n", hrChild);
        }
    } else {
        ViPERLog("[ViPER] No child APO CLSID found in registry (res=%ld)\n", res);
    }

    ViPERLog("[ViPER] Initialize: SUCCESS (child=%p)\n", mChildAPO);
    return S_OK;
}

STDMETHODIMP CViPER4WindowsMFX::IsInputFormatSupported(
    IAudioMediaType *pOppositeFormat,
    IAudioMediaType *pRequestedInputFormat,
    IAudioMediaType **ppSupportedInputFormat
) {
    if (!pRequestedInputFormat || !ppSupportedInputFormat) return E_POINTER;

    UNCOMPRESSEDAUDIOFORMAT format;
    HRESULT hr = pRequestedInputFormat->GetUncompressedAudioFormat(&format);
    if (SUCCEEDED(hr)) {
        ViPERLog(
            "[ViPER] IsInputFormatSupported (this=%p): type=%08X channels=%u bps=%u "
            "container=%u rate=%.0f\n",
            this,
            format.guidFormatType.Data1,
            format.dwSamplesPerFrame,
            format.dwValidBitsPerSample,
            format.dwBytesPerSampleContainer,
            format.fFramesPerSecond
        );
    }

    if (mChildAPO) {
        hr = mChildAPO->IsInputFormatSupported(
            pOppositeFormat, pRequestedInputFormat, ppSupportedInputFormat
        );
        ViPERLog("[ViPER] IsInputFormatSupported: child returned hr=0x%08X\n", hr);
        if (SUCCEEDED(hr)) return hr;
    }

    hr = CBaseAudioProcessingObject::IsInputFormatSupported(
        pOppositeFormat, pRequestedInputFormat, ppSupportedInputFormat
    );
    ViPERLog(
        "[ViPER] IsInputFormatSupported (this=%p): base returned hr=0x%08X\n", this, hr
    );
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

    if (mChildCfg) {
        HRESULT hrChild = mChildCfg->LockForProcess(
            u32NumInputConnections,
            ppInputConnections,
            u32NumOutputConnections,
            ppOutputConnections
        );
        ViPERLog("[ViPER] Child LockForProcess hr=0x%08X\n", hrChild);
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
        mChannelCount = format.dwSamplesPerFrame;
        mSampleRate = static_cast<UINT32>(format.fFramesPerSecond);
    }
    if (mChannelCount == 0) mChannelCount = 2;
    mMaxFrames = ppInputConnections[0]->u32MaxFrameCount;

    if (mEngine) {
        mEngine->SetSamplingRate(mSampleRate);
        mEngine->resetAllEffects();
        mProcessBuffer.resize(mMaxFrames * mChannelCount);
        ViPERLog(
            "[ViPER] Engine configured: rate=%u buffer=%zu\n",
            mSampleRate,
            mProcessBuffer.size()
        );
    }

    if (mSharedParams) {
        mSharedParams->apoSampleRate = mSampleRate;
    }

    ViPERLog(
        "[ViPER] LockForProcess (this=%p): SUCCESS ch=%u rate=%u maxFrames=%u\n",
        this,
        mChannelCount,
        mSampleRate,
        mMaxFrames
    );
    return S_OK;
}

STDMETHODIMP CViPER4WindowsMFX::UnlockForProcess() {
    ViPERLog("[ViPER] UnlockForProcess called (this=%p)\n", this);
    if (mChildCfg) {
        mChildCfg->UnlockForProcess();
    }
    return CBaseAudioProcessingObject::UnlockForProcess();
}

#pragma AVRT_CODE_BEGIN
STDMETHODIMP_(void) CViPER4WindowsMFX::APOProcess(
    UINT32 u32NumInputConnections,
    APO_CONNECTION_PROPERTY** ppInputConnections,
    UINT32 u32NumOutputConnections,
    APO_CONNECTION_PROPERTY** ppOutputConnections)
{
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
            mChildRT,
            (ppInputConnections[0]->u32ValidFrameCount > 0 && pIn) ? pIn[0] : 0.0f
        );
    }
    apoProcessCount++;

    if (mSharedParams && (apoProcessCount & 0x3F) == 0) {
        auto now = std::chrono::system_clock::now();
        auto ms =
            std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch())
                .count();
        mSharedParams->apoProcessTimeMs = static_cast<uint64_t>(ms);
        mSharedParams->apoSampleRate = mSampleRate;
    }

    if (mChildRT) {
        mChildRT->APOProcess(
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
            UINT32 frameCount = ppInputConnections[0]->u32ValidFrameCount;

            if (ppInputConnections[0]->u32BufferFlags == BUFFER_SILENT) {
                memset(pInput, 0, frameCount * mChannelCount * sizeof(float));
            }

            if (!mChildRT && pOutput != pInput) {
                memcpy(pOutput, pInput, frameCount * mChannelCount * sizeof(float));
            }

            bool masterOn = mMasterEnabled.load(std::memory_order_relaxed);
            if (mEngine && frameCount > 0 && masterOn) {
                UINT32 totalSamples = frameCount * mChannelCount;
                if (mProcessBuffer.size() < totalSamples) {
                    mProcessBuffer.resize(totalSamples);
                }
                memcpy(mProcessBuffer.data(), pOutput, totalSamples * sizeof(float));
                float beforeSample = mProcessBuffer[0];
                {
                    std::lock_guard<std::mutex> g(mEngineLock);
                    mEngine->process(mProcessBuffer, frameCount);
                }
                float afterSample = mProcessBuffer[0];
                if (apoProcessCount < 15) {
                    ViPERLog(
                        "[ViPER] Engine: before=%.6f after=%.6f delta=%.6f scale=%.3f\n",
                        beforeSample,
                        afterSample,
                        afterSample - beforeSample,
                        (beforeSample != 0.0f) ? afterSample / beforeSample : 0.0f
                    );
                }
                memcpy(pOutput, mProcessBuffer.data(), totalSamples * sizeof(float));
            }

            ppOutputConnections[0]->u32ValidFrameCount = frameCount;
            ppOutputConnections[0]->u32BufferFlags = BUFFER_VALID;
            break;
        }
        default:
            break;
    }
}
#pragma AVRT_CODE_END

void CViPER4WindowsMFX::TryOpenSharedMemory() {
    if (mSharedParams) return;

    ULONGLONG now = GetTickCount64();
    if (mLastShmAttempt != 0 && (now - mLastShmAttempt) < 1000) return;
    mLastShmAttempt = now;

    mMapFile = OpenFileMappingW(FILE_MAP_READ | FILE_MAP_WRITE, FALSE, VIPER_SHM_NAME);
    DWORD openErr = GetLastError();
    if (mMapFile) {
        mSharedParams = static_cast<ViPERSharedParams *>(MapViewOfFile(
            mMapFile, FILE_MAP_READ | FILE_MAP_WRITE, 0, 0, sizeof(ViPERSharedParams)
        ));
        if (mSharedParams) {
            mSharedParams->apoSampleRate = mSampleRate;
            snprintf(
                mSharedParams->apoVersionString,
                sizeof(mSharedParams->apoVersionString),
                "%s(%s)",
                VERSION_NAME,
                VIPER_STRINGIFY(VERSION_CODE)
            );
            strncpy_s(
                mSharedParams->apoArchString,
                sizeof(mSharedParams->apoArchString),
                kArch,
                _TRUNCATE
            );
            mLastSequence.store(UINT32_MAX, std::memory_order_relaxed);
            ViPERLog("[ViPER] TryOpenSharedMemory: SUCCESS shm=%p\n", mSharedParams);
        } else {
            ViPERLog(
                "[ViPER] TryOpenSharedMemory: MapViewOfFile FAILED err=%lu\n",
                GetLastError()
            );
            CloseHandle(mMapFile);
            mMapFile = nullptr;
        }
    } else {
        ViPERLog(
            "[ViPER] TryOpenSharedMemory: OpenFileMapping FAILED err=%lu\n", openErr
        );
    }

    if (!mParamEvent) {
        mParamEvent = OpenEventW(SYNCHRONIZE, FALSE, VIPER_EVENT_NAME);
    }
    if (!mBulkMapFile) {
        mBulkMapFile = OpenFileMappingW(FILE_MAP_READ, FALSE, VIPER_BULK_SHM_NAME);
        if (mBulkMapFile) {
            mBulkData =
                MapViewOfFile(mBulkMapFile, FILE_MAP_READ, 0, 0, VIPER_BULK_SHM_SIZE);
        }
    }
    if (!mBulkEvent) {
        mBulkEvent = OpenEventW(SYNCHRONIZE, FALSE, VIPER_BULK_EVENT_NAME);
    }
    if (!mBulkAckEvent) {
        mBulkAckEvent = OpenEventW(EVENT_MODIFY_STATE, FALSE, VIPER_BULK_ACK_EVENT_NAME);
    }
}

void CViPER4WindowsMFX::CloseSharedMemory() {
    if (mSharedParams) {
        UnmapViewOfFile(mSharedParams);
        mSharedParams = nullptr;
    }
    if (mMapFile) {
        CloseHandle(mMapFile);
        mMapFile = nullptr;
    }
    if (mParamEvent) {
        CloseHandle(mParamEvent);
        mParamEvent = nullptr;
    }
    if (mBulkData) {
        UnmapViewOfFile(mBulkData);
        mBulkData = nullptr;
    }
    if (mBulkMapFile) {
        CloseHandle(mBulkMapFile);
        mBulkMapFile = nullptr;
    }
    if (mBulkEvent) {
        CloseHandle(mBulkEvent);
        mBulkEvent = nullptr;
    }
    if (mBulkAckEvent) {
        CloseHandle(mBulkAckEvent);
        mBulkAckEvent = nullptr;
    }
}

void CViPER4WindowsMFX::StartParamWatch() {
    mShutdownEvent = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    mWatchThread = CreateThread(nullptr, 0, ParamWatchThread, this, 0, nullptr);
}

void CViPER4WindowsMFX::StopParamWatch() {
    if (mShutdownEvent) {
        SetEvent(mShutdownEvent);
    }
    if (mWatchThread) {
        WaitForSingleObject(mWatchThread, 2000);
        CloseHandle(mWatchThread);
        mWatchThread = nullptr;
    }
    if (mShutdownEvent) {
        CloseHandle(mShutdownEvent);
        mShutdownEvent = nullptr;
    }
}

unsigned long __stdcall CViPER4WindowsMFX::ParamWatchThread(void *parameter) {
    auto *self = static_cast<CViPER4WindowsMFX *>(parameter);

    while (true) {
        self->TryOpenSharedMemory();

        self->CheckAndApplyParams();

        HANDLE handles[3] = {self->mShutdownEvent, nullptr, nullptr};
        DWORD handleCount = 1;
        if (self->mParamEvent) {
            handles[handleCount++] = self->mParamEvent;
        }
        if (self->mBulkEvent) {
            handles[handleCount++] = self->mBulkEvent;
        }

        DWORD timeout = (handleCount > 1) ? INFINITE : 1000;
        DWORD result = WaitForMultipleObjects(handleCount, handles, FALSE, timeout);
        if (result == WAIT_OBJECT_0) break;

        if (handleCount == 3 && result == WAIT_OBJECT_0 + 2) {
            self->ProcessBulkData();
            if (self->mBulkAckEvent) SetEvent(self->mBulkAckEvent);
        }

        self->CheckAndApplyParams();
    }
    return 0;
}

void CViPER4WindowsMFX::CheckAndApplyParams() {
    if (!mSharedParams) return;

    uint32_t seq = mSharedParams->sequenceNumber;
    if (seq != mLastSequence.load(std::memory_order_relaxed)) {
        MemoryBarrier();
        ViPERSharedParams newParams;
        memcpy(&newParams, mSharedParams, sizeof(ViPERSharedParams));
        if (newParams.sequenceNumber != seq) return;
        mLastSequence.store(seq, std::memory_order_relaxed);

        {
            std::lock_guard<std::mutex> g(mEngineLock);
            ApplyParamsToEngine(newParams);
        }
    }
}

void CViPER4WindowsMFX::ProcessBulkData() {
    if (!mBulkData) return;

    auto *hdr = static_cast<const ViPERBulkHeader *>(mBulkData);
    const uint8_t *payload =
        static_cast<const uint8_t *>(mBulkData) + sizeof(ViPERBulkHeader);
    uint32_t maxPayload = VIPER_BULK_SHM_SIZE - sizeof(ViPERBulkHeader);

    if (hdr->dataSize > maxPayload) return;

    std::lock_guard<std::mutex> g(mEngineLock);

    switch (hdr->command) {
        case VIPER_BULK_CMD_DDC: {
            if (hdr->dataSize < 4) break;
            uint32_t arrSize = *reinterpret_cast<const uint32_t *>(payload);
            if (arrSize > hdr->dataSize - 4) break;
            signed char *arr = reinterpret_cast<signed char *>(
                const_cast<uint8_t *>(payload + sizeof(uint32_t))
            );
            mEngine->DispatchCommand(PARAM_HP_DDC_COEFFICIENTS, 0, 0, 0, 0, arrSize, arr);
            break;
        }

        case VIPER_BULK_CMD_CONVOLVER_PREPARE:
            mEngine->DispatchCommand(
                PARAM_HP_CONVOLVER_PREPARE_BUFFER,
                static_cast<int>(hdr->arg1),
                static_cast<int>(hdr->arg2),
                0,
                0,
                0,
                nullptr
            );
            break;

        case VIPER_BULK_CMD_CONVOLVER_CHUNK: {
            if (hdr->dataSize < 8) break;
            int chunkIndex = *reinterpret_cast<const int *>(payload);
            uint32_t floatsInChunk =
                *reinterpret_cast<const uint32_t *>(payload + sizeof(int));
            uint32_t floatDataSize = hdr->dataSize - sizeof(int) - sizeof(uint32_t);
            if (floatsInChunk > floatDataSize) break;
            const uint8_t *floatData = payload + sizeof(int) + sizeof(uint32_t);
            mEngine->DispatchCommand(
                PARAM_HP_CONVOLVER_SET_BUFFER,
                chunkIndex,
                0,
                0,
                0,
                floatsInChunk,
                reinterpret_cast<signed char *>(const_cast<uint8_t *>(floatData))
            );
            break;
        }

        case VIPER_BULK_CMD_CONVOLVER_COMMIT:
            mEngine->DispatchCommand(
                PARAM_HP_CONVOLVER_COMMIT_BUFFER,
                static_cast<int>(hdr->arg1),
                static_cast<int>(hdr->arg2),
                static_cast<int>(hdr->arg3),
                0,
                0,
                nullptr
            );
            break;
    }
}

void CViPER4WindowsMFX::ApplyParamsToEngine(const ViPERSharedParams &p) {
    static unsigned applyCount = 0;
    if (applyCount < 20) {
        ViPERLog(
            "[ViPER] ApplyParamsToEngine #%u: master=%u fxType=%u vol=%u bass=%u "
            "clarity=%u seq=%u\n",
            applyCount,
            p.masterEnabled,
            p.fxType,
            p.outputVolume,
            p.viperBassEnabled,
            p.viperClarityEnabled,
            p.sequenceNumber
        );
    }
    applyCount++;

    auto cmd = [this](int param, int v1, int v2 = 0, int v3 = 0, int v4 = 0) {
        mEngine->DispatchCommand(param, v1, v2, v3, v4, 0, nullptr);
    };

    mMasterEnabled.store(p.masterEnabled != 0, std::memory_order_relaxed);
    if (!p.masterEnabled) {
        mEngine->resetAllEffects();
        return;
    }

    bool isSpk = (p.fxType == 1);
    cmd(PARAM_FX_TYPE_SWITCH, isSpk ? 1 : 0);

    cmd(isSpk ? PARAM_SPK_OUTPUT_VOLUME : PARAM_HP_OUTPUT_VOLUME, p.outputVolume);
    cmd(isSpk ? PARAM_SPK_CHANNEL_PAN : PARAM_HP_CHANNEL_PAN, p.channelPan);
    cmd(isSpk ? PARAM_SPK_LIMITER : PARAM_HP_LIMITER, p.limiterThreshold);

    cmd(isSpk ? PARAM_SPK_AGC_ENABLE : PARAM_HP_AGC_ENABLE, p.agcEnabled);
    cmd(isSpk ? PARAM_SPK_AGC_RATIO : PARAM_HP_AGC_RATIO, p.agcStrength);
    cmd(isSpk ? PARAM_SPK_AGC_VOLUME : PARAM_HP_AGC_VOLUME, p.agcThreshold);
    cmd(isSpk ? PARAM_SPK_AGC_MAX_SCALER : PARAM_HP_AGC_MAX_SCALER, p.agcMaxGain);

    cmd(isSpk ? PARAM_SPK_DDC_ENABLE : PARAM_HP_DDC_ENABLE, p.ddcEnabled);

    cmd(isSpk ? PARAM_SPK_FET_COMPRESSOR_ENABLE : PARAM_HP_FET_COMPRESSOR_ENABLE,
        p.fetCompressorEnabled);
    cmd(isSpk ? PARAM_SPK_FET_COMPRESSOR_THRESHOLD : PARAM_HP_FET_COMPRESSOR_THRESHOLD,
        p.fetCompressorThreshold);
    cmd(isSpk ? PARAM_SPK_FET_COMPRESSOR_RATIO : PARAM_HP_FET_COMPRESSOR_RATIO,
        p.fetCompressorRatio);
    cmd(isSpk ? PARAM_SPK_FET_COMPRESSOR_KNEE : PARAM_HP_FET_COMPRESSOR_KNEE,
        p.fetCompressorKnee);
    cmd(isSpk ? PARAM_SPK_FET_COMPRESSOR_AUTO_KNEE : PARAM_HP_FET_COMPRESSOR_AUTO_KNEE,
        p.fetCompressorAutoKnee);
    cmd(isSpk ? PARAM_SPK_FET_COMPRESSOR_GAIN : PARAM_HP_FET_COMPRESSOR_GAIN,
        p.fetCompressorGain);
    cmd(isSpk ? PARAM_SPK_FET_COMPRESSOR_AUTO_GAIN : PARAM_HP_FET_COMPRESSOR_AUTO_GAIN,
        p.fetCompressorAutoGain);
    cmd(isSpk ? PARAM_SPK_FET_COMPRESSOR_ATTACK : PARAM_HP_FET_COMPRESSOR_ATTACK,
        p.fetCompressorAttack);
    cmd(isSpk ? PARAM_SPK_FET_COMPRESSOR_AUTO_ATTACK
              : PARAM_HP_FET_COMPRESSOR_AUTO_ATTACK,
        p.fetCompressorAutoAttack);
    cmd(isSpk ? PARAM_SPK_FET_COMPRESSOR_RELEASE : PARAM_HP_FET_COMPRESSOR_RELEASE,
        p.fetCompressorRelease);
    cmd(isSpk ? PARAM_SPK_FET_COMPRESSOR_AUTO_RELEASE
              : PARAM_HP_FET_COMPRESSOR_AUTO_RELEASE,
        p.fetCompressorAutoRelease);
    cmd(isSpk ? PARAM_SPK_FET_COMPRESSOR_KNEE_MULTI : PARAM_HP_FET_COMPRESSOR_KNEE_MULTI,
        p.fetCompressorKneeMulti);
    cmd(isSpk ? PARAM_SPK_FET_COMPRESSOR_MAX_ATTACK : PARAM_HP_FET_COMPRESSOR_MAX_ATTACK,
        p.fetCompressorMaxAttack);
    cmd(isSpk ? PARAM_SPK_FET_COMPRESSOR_MAX_RELEASE
              : PARAM_HP_FET_COMPRESSOR_MAX_RELEASE,
        p.fetCompressorMaxRelease);
    cmd(isSpk ? PARAM_SPK_FET_COMPRESSOR_CREST : PARAM_HP_FET_COMPRESSOR_CREST,
        p.fetCompressorCrest);
    cmd(isSpk ? PARAM_SPK_FET_COMPRESSOR_ADAPT : PARAM_HP_FET_COMPRESSOR_ADAPT,
        p.fetCompressorAdapt);
    cmd(isSpk ? PARAM_SPK_FET_COMPRESSOR_NO_CLIP : PARAM_HP_FET_COMPRESSOR_NO_CLIP,
        p.fetCompressorNoClip);

    cmd(isSpk ? PARAM_SPK_SPECTRUM_EXTENSION_ENABLE : PARAM_HP_SPECTRUM_EXTENSION_ENABLE,
        p.spectrumExtensionEnabled);
    cmd(isSpk ? PARAM_SPK_SPECTRUM_EXTENSION_BARK : PARAM_HP_SPECTRUM_EXTENSION_BARK,
        p.spectrumExtensionBark);
    cmd(isSpk ? PARAM_SPK_SPECTRUM_EXTENSION_BARK_RECONSTRUCT
              : PARAM_HP_SPECTRUM_EXTENSION_BARK_RECONSTRUCT,
        p.spectrumExtensionExciter);

    cmd(isSpk ? PARAM_SPK_EQ_ENABLE : PARAM_HP_EQ_ENABLE, p.equalizerEnabled);
    cmd(isSpk ? PARAM_SPK_EQ_BAND_COUNT : PARAM_HP_EQ_BAND_COUNT, p.equalizerBandCount);
    for (uint32_t i = 0; i < p.equalizerBandCount && i < 31; i++) {
        cmd(isSpk ? PARAM_SPK_EQ_BAND_LEVEL : PARAM_HP_EQ_BAND_LEVEL,
            i,
            p.equalizerBands[i]);
    }

    cmd(isSpk ? PARAM_SPK_CONVOLVER_ENABLE : PARAM_HP_CONVOLVER_ENABLE,
        p.convolutionEnabled);
    cmd(isSpk ? PARAM_SPK_CONVOLVER_CROSS_CHANNEL : PARAM_HP_CONVOLVER_CROSS_CHANNEL,
        p.convolutionCrossChannel);

    cmd(isSpk ? PARAM_SPK_FIELD_SURROUND_ENABLE : PARAM_HP_FIELD_SURROUND_ENABLE,
        p.fieldSurroundEnabled);
    cmd(isSpk ? PARAM_SPK_FIELD_SURROUND_WIDENING : PARAM_HP_FIELD_SURROUND_WIDENING,
        p.fieldSurroundWidening);
    cmd(isSpk ? PARAM_SPK_FIELD_SURROUND_MID_IMAGE : PARAM_HP_FIELD_SURROUND_MID_IMAGE,
        p.fieldSurroundMidImage);
    cmd(isSpk ? PARAM_SPK_FIELD_SURROUND_DEPTH : PARAM_HP_FIELD_SURROUND_DEPTH,
        p.fieldSurroundDepth);

    cmd(isSpk ? PARAM_SPK_DIFF_SURROUND_ENABLE : PARAM_HP_DIFF_SURROUND_ENABLE,
        p.diffSurroundEnabled);
    cmd(isSpk ? PARAM_SPK_DIFF_SURROUND_DELAY : PARAM_HP_DIFF_SURROUND_DELAY,
        p.diffSurroundDelay);
    cmd(isSpk ? PARAM_SPK_DIFF_SURROUND_REVERSE : PARAM_HP_DIFF_SURROUND_REVERSE,
        p.diffSurroundReverse);

    cmd(isSpk ? PARAM_SPK_HEADPHONE_SURROUND_ENABLE : PARAM_HP_HEADPHONE_SURROUND_ENABLE,
        p.vheEnabled);
    cmd(isSpk ? PARAM_SPK_HEADPHONE_SURROUND_STRENGTH
              : PARAM_HP_HEADPHONE_SURROUND_STRENGTH,
        p.vheQuality);

    cmd(isSpk ? PARAM_SPK_REVERB_ENABLE : PARAM_HP_REVERB_ENABLE, p.reverberationEnabled);
    cmd(isSpk ? PARAM_SPK_REVERB_ROOM_SIZE : PARAM_HP_REVERB_ROOM_SIZE,
        p.reverberationRoomSize);
    cmd(isSpk ? PARAM_SPK_REVERB_ROOM_WIDTH : PARAM_HP_REVERB_ROOM_WIDTH,
        p.reverberationRoomWidth);
    cmd(isSpk ? PARAM_SPK_REVERB_ROOM_DAMPENING : PARAM_HP_REVERB_ROOM_DAMPENING,
        p.reverberationRoomDampening);
    cmd(isSpk ? PARAM_SPK_REVERB_ROOM_WET_SIGNAL : PARAM_HP_REVERB_ROOM_WET_SIGNAL,
        p.reverberationWetSignal);
    cmd(isSpk ? PARAM_SPK_REVERB_ROOM_DRY_SIGNAL : PARAM_HP_REVERB_ROOM_DRY_SIGNAL,
        p.reverberationDrySignal);

    cmd(isSpk ? PARAM_SPK_DYNAMIC_SYSTEM_ENABLE : PARAM_HP_DYNAMIC_SYSTEM_ENABLE,
        p.dynamicSystemEnabled);
    cmd(isSpk ? PARAM_SPK_DYNAMIC_SYSTEM_X_COEFFICIENTS
              : PARAM_HP_DYNAMIC_SYSTEM_X_COEFFICIENTS,
        p.dynamicSystemXLow,
        p.dynamicSystemXHigh);
    cmd(isSpk ? PARAM_SPK_DYNAMIC_SYSTEM_Y_COEFFICIENTS
              : PARAM_HP_DYNAMIC_SYSTEM_Y_COEFFICIENTS,
        p.dynamicSystemYLow,
        p.dynamicSystemYHigh);
    cmd(isSpk ? PARAM_SPK_DYNAMIC_SYSTEM_SIDE_GAIN : PARAM_HP_DYNAMIC_SYSTEM_SIDE_GAIN,
        p.dynamicSystemSideGainLow,
        p.dynamicSystemSideGainHigh);
    cmd(isSpk ? PARAM_SPK_DYNAMIC_SYSTEM_STRENGTH : PARAM_HP_DYNAMIC_SYSTEM_STRENGTH,
        p.dynamicSystemStrength);

    cmd(isSpk ? PARAM_SPK_TUBE_SIMULATOR_ENABLE : PARAM_HP_TUBE_SIMULATOR_ENABLE,
        p.tubeSimulatorEnabled);

    cmd(isSpk ? PARAM_SPK_BASS_ENABLE : PARAM_HP_BASS_ENABLE, p.viperBassEnabled);
    cmd(isSpk ? PARAM_SPK_BASS_MODE : PARAM_HP_BASS_MODE, p.viperBassMode);
    cmd(isSpk ? PARAM_SPK_BASS_FREQUENCY : PARAM_HP_BASS_FREQUENCY, p.viperBassFrequency);
    cmd(isSpk ? PARAM_SPK_BASS_GAIN : PARAM_HP_BASS_GAIN, p.viperBassGain);
    cmd(isSpk ? PARAM_SPK_BASS_ANTI_POP : PARAM_HP_BASS_ANTI_POP, p.viperBassAntiPop);

    cmd(isSpk ? PARAM_SPK_BASS_MONO_ENABLE : PARAM_HP_BASS_MONO_ENABLE,
        p.viperBassMonoEnabled);
    cmd(isSpk ? PARAM_SPK_BASS_MONO_MODE : PARAM_HP_BASS_MONO_MODE, p.viperBassMonoMode);
    cmd(isSpk ? PARAM_SPK_BASS_MONO_FREQUENCY : PARAM_HP_BASS_MONO_FREQUENCY,
        p.viperBassMonoFrequency);
    cmd(isSpk ? PARAM_SPK_BASS_MONO_GAIN : PARAM_HP_BASS_MONO_GAIN, p.viperBassMonoGain);
    cmd(isSpk ? PARAM_SPK_BASS_MONO_ANTI_POP : PARAM_HP_BASS_MONO_ANTI_POP,
        p.viperBassMonoAntiPop);

    cmd(isSpk ? PARAM_SPK_CLARITY_ENABLE : PARAM_HP_CLARITY_ENABLE,
        p.viperClarityEnabled);
    cmd(isSpk ? PARAM_SPK_CLARITY_MODE : PARAM_HP_CLARITY_MODE, p.viperClarityMode);
    cmd(isSpk ? PARAM_SPK_CLARITY_GAIN : PARAM_HP_CLARITY_GAIN, p.viperClarityGain);

    cmd(isSpk ? PARAM_SPK_CURE_ENABLE : PARAM_HP_CURE_ENABLE, p.cureEnabled);
    cmd(isSpk ? PARAM_SPK_CURE_STRENGTH : PARAM_HP_CURE_STRENGTH,
        p.cureCrossfeedStrength);

    cmd(isSpk ? PARAM_SPK_ANALOGX_ENABLE : PARAM_HP_ANALOGX_ENABLE, p.analogXEnabled);
    cmd(isSpk ? PARAM_SPK_ANALOGX_MODE : PARAM_HP_ANALOGX_MODE, p.analogXMode);

    cmd(PARAM_SPK_SPEAKER_CORRECTION_ENABLE, p.speakerCorrectionEnabled);
}
