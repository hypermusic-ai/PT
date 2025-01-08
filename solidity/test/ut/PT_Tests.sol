// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol"; 

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";

import "../contracts/Runner.sol";
import "../contracts/Registry.sol";

import "../contracts/feature/Pitch.sol";
import "../contracts/feature/Time.sol";
import "../contracts/feature/Duration.sol";
import "../contracts/feature/FeatureA.sol";
import "../contracts/feature/FeatureB.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract testSuite {

    address payable private _wallet;

    address testRegistry;
    IRegistry private _registry;
    address testRunner;

    Pitch _pitch;
    Time _time;
    Duration _duration;
    FeatureA _featureA;
    FeatureB _featureB;

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll(address payable wallet, address registry, address runner) public {
        _wallet = wallet;

        testRegistry = registry;
        testRunner = runner;

        _pitch = Pitch(testRegistry);
        _time = Time(testRegistry);
        _duration = Duration(testRegistry);
        _featureA = FeatureA(testRegistry);
        _featureB = FeatureB(testRegistry);
    }

    function UT0_Pitch(uint32 N) public {
        console.log("Running checkPitch");
        console.log("Call Runner at: ", address(testRunner));
        string memory name = "pitch";
        (bool sucess, bytes memory data) = address(testRunner).call(abi.encodeWithSignature("gen(uint32,string)", N, name));
        require(sucess, "Call to Runner::gen() failed");
        uint32[] memory res = bytesToUint32Array(data);
        console.log("data fetched len: ", res.length);
        for (uint32 i=0; i < res.length; ++i)
        {
            console.log(res[i]);
        }
        console.log("checkPitch ended");
    }
}