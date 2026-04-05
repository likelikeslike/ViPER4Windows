#pragma once

#include <BaseAudioProcessingObject.h>
#include <atlbase.h>
#include <atlcom.h>
#include <audioenginebaseapo.h>
#include <mmdeviceapi.h>

#include <atomic>
#include <memory>
#include <mutex>
#include <vector>

#include "SharedParams.h"

// {B5A2C3D4-E6F7-4A8B-9C0D-1E2F3A4B5C6D}
DEFINE_GUID(
    CLSID_ViPER4WindowsMFX,
    0xb5a2c3d4,
    0xe6f7,
    0x4a8b,
    0x9c,
    0x0d,
    0x1e,
    0x2f,
    0x3a,
    0x4b,
    0x5c,
    0x6d
);

class ViPER;

class __declspec(uuid("B5A2C3D4-E6F7-4A8B-9C0D-1E2F3A4B5C6D")) CViPER4WindowsMFX
    : public CComObjectRootEx<CComMultiThreadModel>,
      public CComCoClass<CViPER4WindowsMFX, &CLSID_ViPER4WindowsMFX>,
      public CBaseAudioProcessingObject,
      public IAudioSystemEffects {
public:
    CViPER4WindowsMFX();
    ~CViPER4WindowsMFX();

    DECLARE_POLY_AGGREGATABLE(CViPER4WindowsMFX)

    BEGIN_COM_MAP(CViPER4WindowsMFX)
    COM_INTERFACE_ENTRY(IAudioSystemEffects)
    COM_INTERFACE_ENTRY(IAudioProcessingObjectRT)
    COM_INTERFACE_ENTRY(IAudioProcessingObject)
    COM_INTERFACE_ENTRY(IAudioProcessingObjectConfiguration)
    END_COM_MAP()

    DECLARE_PROTECT_FINAL_CONSTRUCT()
    DECLARE_NO_REGISTRY()

    HRESULT FinalConstruct();

    // IAudioProcessingObject
    STDMETHOD(GetLatency)(HNSTIME *pTime);
    STDMETHOD(Initialize)(UINT32 cbDataSize, BYTE *pbyData);
    STDMETHOD(IsInputFormatSupported)(
        IAudioMediaType *pOppositeFormat,
        IAudioMediaType *pRequestedInputFormat,
        IAudioMediaType **ppSupportedInputFormat
    );

    // IAudioProcessingObjectConfiguration
    STDMETHOD(LockForProcess)(
        UINT32 u32NumInputConnections,
        APO_CONNECTION_DESCRIPTOR **ppInputConnections,
        UINT32 u32NumOutputConnections,
        APO_CONNECTION_DESCRIPTOR **ppOutputConnections
    );
    STDMETHOD(UnlockForProcess)();

    // IAudioProcessingObjectRT
    STDMETHOD_(void, APOProcess)(
        UINT32 u32NumInputConnections,
        APO_CONNECTION_PROPERTY **ppInputConnections,
        UINT32 u32NumOutputConnections,
        APO_CONNECTION_PROPERTY **ppOutputConnections
    );

    static const CRegAPOProperties<1> RegProperties;

private:
    void TryOpenSharedMemory();
    void CloseSharedMemory();
    void ApplyParamsToEngine(const ViPERSharedParams &params);
    void ProcessBulkData();
    void CheckAndApplyParams();

    static unsigned long __stdcall ParamWatchThread(void *parameter);
    void StartParamWatch();
    void StopParamWatch();
    void ResetChild();

    std::unique_ptr<ViPER> mEngine;
    std::mutex mEngineLock;
    std::vector<float> mProcessBuffer;

    HANDLE mMapFile = nullptr;
    ViPERSharedParams *mSharedParams = nullptr;
    std::atomic<uint32_t> mLastSequence{0};
    std::atomic<bool> mMasterEnabled{true};
    ULONGLONG mLastShmAttempt = 0;

    HANDLE mBulkMapFile = nullptr;
    void *mBulkData = nullptr;
    HANDLE mBulkEvent = nullptr;
    HANDLE mBulkAckEvent = nullptr;

    HANDLE mParamEvent = nullptr;
    HANDLE mShutdownEvent = nullptr;
    HANDLE mWatchThread = nullptr;

    UINT32 mChannelCount = 2;
    UINT32 mSampleRate = 48000;
    UINT32 mMaxFrames = 0;

    IAudioProcessingObject *mChildAPO = nullptr;
    IAudioProcessingObjectRT *mChildRT = nullptr;
    IAudioProcessingObjectConfiguration *mChildCfg = nullptr;
};
