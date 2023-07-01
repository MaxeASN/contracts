// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

import {calldataKeccak} from "../core/Helpers.sol";

/**
 * DID_Document struct
 * 用于存储DID的相关信息
 * @param context 对DID文档的相关说明
 * @param id 本DID文档对应的DID标识
 * @param version 版本信息
 * @param timeCreated 创建时间
 * @param timeUpdated 更新时间
 * @param authenticationPublicKey 用于认证的公钥
 * @param recoveryPublicKey 用于恢复的公钥
 * @param service 对应的服务端的信息
 * @param proof 用于验证的信息
 */
//要注意结构体内部变量的顺序，这关乎到前端那边生成参数时的排序
struct DID_Document {
    string context;
    string id;
    string version;
    string timeCreated;
    string timeUpdated;
    PublicKey authenticationPublicKey;
    PublicKey recoveryPublicKey;
    Service service;
    Proof proof;
}

struct PublicKey {
    string id;
    string algriothmType;
    bytes publicKeyHex;
}
struct Service {
    string id;
    string serviceType;
    string serviceEndpoint;
}
struct Proof {
    string proofType;
    string creator;
    string signatureValue;
}

/**
 * Utility functions helpful when working with UserOperation structs.
 */
library DIDLib {

}
