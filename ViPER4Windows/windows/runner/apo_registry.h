#ifndef RUNNER_APO_REGISTRY_H_
#define RUNNER_APO_REGISTRY_H_

#include <flutter/binary_messenger.h>

// Registers the "v4w/apo_registry" MethodChannel that performs HKLM
// MMDevices\Audio\Render\<endpoint>\FxProperties writes natively, taking
// ownership and rewriting the DACL when keys are TrustedInstaller-owned.
void RegisterApoRegistryChannel(flutter::BinaryMessenger* messenger);

#endif  // RUNNER_APO_REGISTRY_H_
