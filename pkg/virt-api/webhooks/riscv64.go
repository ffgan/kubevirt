/*
 * This file is part of the KubeVirt project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
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
 * Copyright The KubeVirt Authors.
 *
 */

package webhooks

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	k8sfield "k8s.io/apimachinery/pkg/util/validation/field"

	v1 "kubevirt.io/api/core/v1"
)

var _false_rv bool = false

const (
	defaultCPUModelRiscv64 = v1.CPUModeHostPassthrough
)

// ValidateVirtualMachineInstanceRiscv64Setting is a validation function for validating-webhook to filter unsupported setting on Riscv64
func ValidateVirtualMachineInstanceRiscv64Setting(field *k8sfield.Path, spec *v1.VirtualMachineInstanceSpec) []metav1.StatusCause {
	var statusCauses []metav1.StatusCause
	validateBootOptions_rv(field, spec, &statusCauses)
	validateCPUModel_rv(field, spec, &statusCauses)
	validateDiskBus_rv(field, spec, &statusCauses)
	validateWatchdog_rv(field, spec, &statusCauses)
	validateSoundDevice_rv(field, spec, &statusCauses)
	return statusCauses
}

func validateBootOptions_rv(field *k8sfield.Path, spec *v1.VirtualMachineInstanceSpec, statusCauses *[]metav1.StatusCause) {
	if spec.Domain.Firmware != nil && spec.Domain.Firmware.Bootloader != nil {
		if spec.Domain.Firmware.Bootloader.BIOS != nil {
			*statusCauses = append(*statusCauses, metav1.StatusCause{
				Type:    metav1.CauseTypeFieldValueNotSupported,
				Message: "Riscv64 does not support bios boot, please change to uefi boot",
				Field:   field.Child("domain", "firmware", "bootloader", "bios").String(),
			})
		}
		if spec.Domain.Firmware.Bootloader.EFI != nil {
			if spec.Domain.Firmware.Bootloader.EFI.SecureBoot == nil || (spec.Domain.Firmware.Bootloader.EFI.SecureBoot != nil && *spec.Domain.Firmware.Bootloader.EFI.SecureBoot) {
				*statusCauses = append(*statusCauses, metav1.StatusCause{
					Type:    metav1.CauseTypeFieldValueNotSupported,
					Message: "UEFI secure boot is currently not supported on riscv64 Arch",
					Field:   field.Child("domain", "firmware", "bootloader", "efi", "secureboot").String(),
				})
			}
		}
	}
}

func validateCPUModel_rv(field *k8sfield.Path, spec *v1.VirtualMachineInstanceSpec, statusCauses *[]metav1.StatusCause) {
	if spec.Domain.CPU != nil && (&spec.Domain.CPU.Model != nil) && spec.Domain.CPU.Model == "host-model" {
		*statusCauses = append(*statusCauses, metav1.StatusCause{
			Type:    metav1.CauseTypeFieldValueNotSupported,
			Message: "Riscv64 not support CPU host-model",
			Field:   field.Child("domain", "cpu", "model").String(),
		})
	}
}

func validateDiskBus_rv(field *k8sfield.Path, spec *v1.VirtualMachineInstanceSpec, statusCauses *[]metav1.StatusCause) {
	if spec.Domain.Devices.Disks != nil {
		// checkIfBusAvailable: if bus type is nil, virtio, scsi return true, otherwise, return false
		checkIfBusAvailable := func(bus v1.DiskBus) bool {
			if bus == "" || bus == v1.DiskBusVirtio || bus == v1.DiskBusSCSI {
				return true
			}
			return false
		}

		for i, disk := range spec.Domain.Devices.Disks {
			if disk.Disk != nil && !checkIfBusAvailable(disk.Disk.Bus) {
				*statusCauses = append(*statusCauses, metav1.StatusCause{
					Type:    metav1.CauseTypeFieldValueNotSupported,
					Message: "Riscv64 does not support this disk bus type, please use virtio or scsi",
					Field:   field.Child("domain", "devices", "disks").Index(i).Child("disk", "bus").String(),
				})
			}
			if disk.CDRom != nil && !checkIfBusAvailable(disk.CDRom.Bus) {
				*statusCauses = append(*statusCauses, metav1.StatusCause{
					Type:    metav1.CauseTypeFieldValueNotSupported,
					Message: "Riscv64 does not support this disk bus type, please use virtio or scsi",
					Field:   field.Child("domain", "devices", "disks").Index(i).Child("cdrom", "bus").String(),
				})
			}
			if disk.LUN != nil && !checkIfBusAvailable(disk.LUN.Bus) {
				*statusCauses = append(*statusCauses, metav1.StatusCause{
					Type:    metav1.CauseTypeFieldValueNotSupported,
					Message: "Riscv64 does not support this disk bus type, please use virtio or scsi",
					Field:   field.Child("domain", "devices", "disks").Index(i).Child("lun", "bus").String(),
				})
			}
		}
	}
}

func validateWatchdog_rv(field *k8sfield.Path, spec *v1.VirtualMachineInstanceSpec, statusCauses *[]metav1.StatusCause) {
	if spec.Domain.Devices.Watchdog != nil {
		*statusCauses = append(*statusCauses, metav1.StatusCause{
			Type:    metav1.CauseTypeFieldValueNotSupported,
			Message: "Riscv64 not support Watchdog device",
			Field:   field.Child("domain", "devices", "watchdog").String(),
		})
	}
}

func IsRISCV64(vmiSpec *v1.VirtualMachineInstanceSpec) bool {
	return vmiSpec.Architecture == "riscv64"
}

func validateSoundDevice_rv(field *k8sfield.Path, spec *v1.VirtualMachineInstanceSpec, statusCauses *[]metav1.StatusCause) {
	if spec.Domain.Devices.Sound != nil {
		*statusCauses = append(*statusCauses, metav1.StatusCause{
			Type:    metav1.CauseTypeFieldValueNotSupported,
			Message: "Riscv64 not support sound device",
			Field:   field.Child("domain", "devices", "sound").String(),
		})
	}
}
