#pragma once

#include <BaseAudioProcessingObject.h>
#include <atlbase.h>
#include <atlcom.h>
#include <atomic>
#include <audioenginebaseapo.h>
#include <memory>
#include <mmdeviceapi.h>
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
    STDMETHOD(GetRegistrationProperties)(APO_REG_PROPERTIES **ppRegProps);
    STDMETHOD(Initialize)(UINT32 cbDataSize, BYTE *pbyData);
    STDMETHOD(IsInputFormatSupported)(
        IAudioMediaType *pOppositeFormat,
        IAudioMediaType *pRequestedInputFormat,
        IAudioMediaType **ppSupportedInputFormat
    );
    STDMETHOD(IsOutputFormatSupported)(
        IAudioMediaType *pOppositeFormat,
        IAudioMediaType *pRequestedOutputFormat,
        IAudioMediaType **ppSupportedOutputFormat
    );
    STDMETHOD(Reset)();

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
    void ApplyParamsToEngine(const viper::ViPERParams &params);
    bool CheckAndReloadBulk(uint32_t base, uint32_t region_size, uint32_t &last_seq);
    void DispatchBulk(
        const ViPERBulkHeader &hdr, const uint8_t *payload, uint32_t region_size
    );
    void CheckAndApplyParams();
    void WriteStatusShm();

    static unsigned long __stdcall ParamWatchThread(void *parameter);
    void StartParamWatch();
    void StopParamWatch();
    void ResetChild();

    std::unique_ptr<ViPER> engine_;
    std::mutex engine_lock_;
    std::vector<float> process_buffer_;

    std::atomic<viper::ViPERParams *> staged_params_{nullptr};
    std::atomic<viper::ViPERParams *> consumed_params_{nullptr};
    std::atomic<bool> staged_master_off_{false};

    HANDLE params_map_ = nullptr;
    uint8_t *params_base_ = nullptr;
    uint32_t last_update_count_ = 0;
    std::atomic<bool> master_enabled_{true};
    ULONGLONG last_shm_attempt_ = 0;

    HANDLE status_map_ = nullptr;
    uint8_t *status_base_ = nullptr;
    uint32_t status_seq_ = 0;

    HANDLE bulk_map_file_ = nullptr;
    void *bulk_data_ = nullptr;
    HANDLE bulk_event_ = nullptr;
    uint32_t last_bulk_ddc_seq_ = 0;
    uint32_t last_bulk_convolver_seq_ = 0;

    HANDLE param_event_ = nullptr;
    HANDLE shutdown_event_ = nullptr;
    HANDLE watch_thread_ = nullptr;

    UINT32 channel_count_ = 2;
    UINT32 sample_rate_ = 48000;
    UINT32 max_frames_ = 0;

    IAudioProcessingObject *child_apo_ = nullptr;
    IAudioProcessingObjectRT *child_rt_ = nullptr;
    IAudioProcessingObjectConfiguration *child_cfg_ = nullptr;

    wchar_t endpoint_id_[64] = {};
};
