// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

error FeatureAlreadyRegistered(bytes32 name);
error FeatureMissing(bytes32 name);

error TransformationAlreadyRegistered(bytes32 name);
error TransformationArgumentsMismatch(bytes32 name);
error TransformationMissing(bytes32 name);

error ConditionAlreadyRegistered(bytes32 name);
error ConditionArgumentsMismatch(bytes32 name);
error ConditionMissing(bytes32 name);

error RegistryError(uint32 code);

error ConditionNotMet(bytes32 name);