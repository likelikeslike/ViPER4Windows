#ifndef VIPER4WINDOWS_SHARED_PARAMS_H
#define VIPER4WINDOWS_SHARED_PARAMS_H

#include <cstdint>

#define VIPER_SHM_NAME L"Global\\ViPER4Windows_Params"
#define VIPER_EVENT_NAME L"Global\\ViPER4Windows_ParamsChanged"

#pragma pack(push, 1)
struct ViPERSharedParams {
    uint32_t version;
    uint32_t sequenceNumber;

    uint32_t masterEnabled;
    uint32_t fxType;

    uint32_t outputVolume;
    int32_t channelPan;
    uint32_t limiterThreshold;

    uint32_t agcEnabled;
    uint32_t agcStrength;
    uint32_t agcMaxGain;
    uint32_t agcThreshold;

    uint32_t fetCompressorEnabled;
    int32_t fetCompressorThreshold;
    int32_t fetCompressorRatio;
    uint32_t fetCompressorAutoKnee;
    int32_t fetCompressorKnee;
    int32_t fetCompressorKneeMulti;
    uint32_t fetCompressorAutoGain;
    int32_t fetCompressorGain;
    uint32_t fetCompressorAutoAttack;
    int32_t fetCompressorAttack;
    int32_t fetCompressorMaxAttack;
    uint32_t fetCompressorAutoRelease;
    int32_t fetCompressorRelease;
    int32_t fetCompressorMaxRelease;
    int32_t fetCompressorCrest;
    int32_t fetCompressorAdapt;
    uint32_t fetCompressorNoClip;

    uint32_t ddcEnabled;

    uint32_t spectrumExtensionEnabled;
    uint32_t spectrumExtensionBark;
    int32_t spectrumExtensionExciter;

    uint32_t equalizerEnabled;
    uint32_t equalizerBandCount;
    int32_t equalizerBands[31];

    uint32_t convolutionEnabled;
    int32_t convolutionCrossChannel;

    uint32_t fieldSurroundEnabled;
    uint32_t fieldSurroundWidening;
    int32_t fieldSurroundMidImage;
    int32_t fieldSurroundDepth;

    uint32_t diffSurroundEnabled;
    uint32_t diffSurroundDelay;

    uint32_t vheEnabled;
    uint32_t vheQuality;

    uint32_t reverberationEnabled;
    int32_t reverberationRoomSize;
    int32_t reverberationRoomWidth;
    int32_t reverberationRoomDampening;
    int32_t reverberationWetSignal;
    int32_t reverberationDrySignal;

    uint32_t dynamicSystemEnabled;
    int32_t dynamicSystemXLow;
    int32_t dynamicSystemXHigh;
    int32_t dynamicSystemYLow;
    int32_t dynamicSystemYHigh;
    int32_t dynamicSystemSideGainLow;
    int32_t dynamicSystemSideGainHigh;
    int32_t dynamicSystemStrength;

    uint32_t tubeSimulatorEnabled;

    uint32_t viperBassEnabled;
    uint32_t viperBassMode;
    uint32_t viperBassFrequency;
    uint32_t viperBassGain;
    uint32_t viperBassAntiPop;

    uint32_t viperBassMonoEnabled;
    uint32_t viperBassMonoMode;
    uint32_t viperBassMonoFrequency;
    uint32_t viperBassMonoGain;
    uint32_t viperBassMonoAntiPop;

    uint32_t viperClarityEnabled;
    uint32_t viperClarityMode;
    uint32_t viperClarityGain;

    uint32_t cureEnabled;
    uint32_t cureCrossfeedStrength;

    uint32_t analogXEnabled;
    uint32_t analogXMode;

    uint32_t speakerCorrectionEnabled;

    uint32_t apoSampleRate;
    uint64_t apoProcessTimeMs;
    uint32_t _reserved[1];
};
#pragma pack(pop)

static_assert(sizeof(ViPERSharedParams) <= 4096, "SharedParams must fit in a page");

#define VIPER_BULK_SHM_NAME L"Global\\ViPER4Windows_BulkData"
#define VIPER_BULK_EVENT_NAME L"Global\\ViPER4Windows_BulkDataReady"
#define VIPER_BULK_ACK_EVENT_NAME L"Global\\ViPER4Windows_BulkDataAck"
#define VIPER_BULK_SHM_SIZE 65536

#define VIPER_BULK_CMD_DDC 1
#define VIPER_BULK_CMD_CONVOLVER_PREPARE 2
#define VIPER_BULK_CMD_CONVOLVER_CHUNK 3
#define VIPER_BULK_CMD_CONVOLVER_COMMIT 4

#pragma pack(push, 1)
struct ViPERBulkHeader {
    uint32_t command;
    uint32_t param;
    uint32_t dataSize;
    uint32_t arg1;
    uint32_t arg2;
    uint32_t arg3;
    uint32_t arg4;
    uint32_t _pad;
};
#pragma pack(pop)

static_assert(sizeof(ViPERBulkHeader) == 32, "BulkHeader must be 32 bytes");

#endif
