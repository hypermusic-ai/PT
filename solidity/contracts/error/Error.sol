// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

error FeatureAlreadyRegistered(bytes32 name);
error FeatureMissing(bytes32 name);

error TransformationAlreadyRegistered(bytes32 name);
error TransformationArgumentsMismatch(bytes32 name);
error TransformationMissing(bytes32 name);

error RunInstanceAlreadyRegistered(bytes32 featureName, bytes32 runInstanceName);
error RunInstanceMissing(bytes32 featureName, bytes32 runInstanceName);

error RegistryError(uint32 code);