#ifndef VIPER4WINDOWS_SHARED_PARAMS_H
#define VIPER4WINDOWS_SHARED_PARAMS_H

#include <cstdint>

#include "include/ViPERParams.h"

#define VIPER_PARAMS_SHM_NAME L"Global\\ViPER4Windows_Params"
#define VIPER_STATUS_SHM_NAME L"Global\\ViPER4Windows_Status"
#define VIPER_EVENT_NAME L"Global\\ViPER4Windows_ParamsChanged"

#define VIPER_PARAMS_SHM_SIZE 4096
#define VIPER_STATUS_SHM_SIZE 256
#define VIPER_FORMAT_VERSION 2
#define VIPER_SHM_MAGIC 0x534D3456 // 'V4MS' little-endian-ish

#pragma pack(push, 4)
struct V4WHeader {
    uint32_t magic;
    uint32_t version;
    uint32_t active_index;
    uint32_t update_count;
    uint32_t master_enabled;
    uint32_t _pad;
};
#pragma pack(pop)
static_assert(sizeof(V4WHeader) == 24, "V4WHeader must be 24 bytes");

constexpr uint32_t kV4WSlotAOffset = sizeof(V4WHeader);
constexpr uint32_t kV4WSlotBOffset = kV4WSlotAOffset + sizeof(viper::ViPERParams);

static_assert(
    kV4WSlotBOffset + sizeof(viper::ViPERParams) <= VIPER_PARAMS_SHM_SIZE,
    "Two ViPERParams snapshots + V4WHeader must fit in shm_params"
);

#pragma pack(push, 4)
struct V4WStatus {
    uint32_t magic;
    uint32_t version;
    uint32_t status_seq;

    uint32_t enabled;
    uint32_t configured;
    uint32_t sample_rate;
    uint64_t processedFrames;

    char version_name[32];
    char arch_string[16];
};
#pragma pack(pop)

static_assert(
    sizeof(V4WStatus) <= VIPER_STATUS_SHM_SIZE, "V4WStatus must fit in shm_status"
);

#define VIPER_BULK_SHM_NAME L"Global\\ViPER4Windows_BulkData"
#define VIPER_BULK_EVENT_NAME L"Global\\ViPER4Windows_BulkDataReady"
#define VIPER_BULK_SHM_SIZE (4 * 1024 * 1024)

#define VIPER_BULK_CMD_DDC 1
#define VIPER_BULK_CMD_CONVOLVER_KERNEL 2

#pragma pack(push, 4)
struct ViPERBulkHeader {
    uint32_t magic;
    uint32_t version;
    uint32_t seq;
    uint32_t command;
    uint32_t data_size;

    uint32_t arg1;
    uint32_t arg2;
    uint32_t arg3;
};
#pragma pack(pop)

static_assert(sizeof(ViPERBulkHeader) == 32, "BulkHeader must be 32 bytes");

constexpr uint32_t kBulkDdcBase = 0;
constexpr uint32_t kBulkDdcRegionSize = 2 * 1024 * 1024;
constexpr uint32_t kBulkConvolverBase = kBulkDdcRegionSize;
constexpr uint32_t kBulkConvolverRegionSize = 2 * 1024 * 1024;

constexpr uint32_t kBulkHeaderSize = sizeof(ViPERBulkHeader);
constexpr uint32_t kBulkDdcMaxPayload = kBulkDdcRegionSize - kBulkHeaderSize;
constexpr uint32_t kBulkConvolverMaxPayload = kBulkConvolverRegionSize - kBulkHeaderSize;

#endif
