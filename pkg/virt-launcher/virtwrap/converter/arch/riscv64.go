/* Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * Copyright the KubeVirt Authors.
 *
 */

package arch

import (
	v1 "kubevirt.io/api/core/v1"

	"kubevirt.io/kubevirt/pkg/virt-launcher/virtwrap/api"
)

// Ensure that there is a compile error should the struct not implement the archConverter interface anymore.
var _ = Converter(&converterRISCV64{})

type converterRISCV64 struct{}

func (converterRISCV64) GetArchitecture() string {
	return riscv64
}

func (converterRISCV64) ScsiController(model string, driver *api.ControllerDriver) api.Controller {
	return defaultSCSIController(model, driver)
}

func (converterRISCV64) IsUSBNeeded(_ *v1.VirtualMachineInstance) bool {
	return true
}

func (converterRISCV64) SupportCPUHotplug() bool {
	return false
}

func (converterRISCV64) IsSMBiosNeeded() bool {
	// RISCV64 use UEFI boot by default, set SMBios is unnecessary.
	return false
}

func (converterRISCV64) TransitionalModelType(useVirtioTransitional bool) string {
	return defaultTransitionalModelType(useVirtioTransitional)
}

func (converterRISCV64) IsROMTuningSupported() bool {
	return true
}

func (converterRISCV64) RequiresMPXCPUValidation() bool {
	// skip the mpx CPU feature validation for anything that is not x86 as it is not supported.
	return false
}

func (converterRISCV64) ShouldVerboseLogsBeEnabled() bool {
	return false
}

func (converterRISCV64) HasVMPort() bool {
	return false
}

func (converterRISCV64) SupportPCIHole64Disabling() bool {
	return false
}
