//
//  VcxWrapper.swift
//  VcxDemo
//
//  Created by Jeong Kim on 16/06/2020.
//  Copyright © 2020 SK Telecom. All rights reserved.
//

import Foundation
import Combine

class VcxWrapper {

    func agentProvisionAsync(config: String) -> Future<String, Error> {
        return Future { promise in
            ConnectMeVcx().agentProvisionAsync(config) { error, config in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("create config was successful: \(config!)")
                    promise(.success(config!))
                }
            }
        }
    }
    
    func vcxInitCore(config: String) -> Int {
        return Int(ConnectMeVcx().vcxInitCore(config))
    }
    
    func vcxOpenWallet() -> Future<String, Error> {
        return Future { promise in
            ConnectMeVcx().vcxOpenWallet() { error in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("vcxOpenWallet was successful!")
                    promise(.success(""))
                }
            }
        }
    }
    
    func vcxOpenPool() -> Future<String, Error> {
        return Future { promise in
            ConnectMeVcx().vcxOpenPool() { error in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("vcxOpenPool was successful!")
                    promise(.success(""))
                }
            }
        }
    }
    
    func connectionCreateWithInvite(invitationId: String, inviteDetails: String) -> Future<Int, Error> {
        return Future { promise in
            ConnectMeVcx().connectionCreate(withInvite: invitationId, inviteDetails: inviteDetails) { error, connectionHandle in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("createConnectionWithInvite was successful!")
                    promise(.success(connectionHandle))
                }
            }
        }
    }
    
    func connectionConnect(connectionHandle: Int, connectionType: String) -> Future<String, Error> {
        return Future { promise in
            ConnectMeVcx().connectionConnect(VcxHandle(truncatingIfNeeded: connectionHandle), connectionType: connectionType) { error, inviteDetails in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("connectionConnect was successful!")
                    promise(.success(inviteDetails!))
                }
            }
        }
    }
    
    func connectionUpdateState(connectionHandle: Int) -> Future<Int, Error> {
        return Future { promise in
            ConnectMeVcx().connectionUpdateState(connectionHandle) { error, state in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("connectionUpdateState was successful!")
                    promise(.success(state))
                }
            }
        }
    }
    
    func connectionGetState(connectionHandle: Int) -> Future<Int, Error> {
        return Future { promise in
            ConnectMeVcx().connectionGetState(connectionHandle) { error, state in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("connectionGetState was successful!")
                    promise(.success(state))
                }
            }
        }
    }
    
    func connectionSerialize(connectionHandle: Int) -> Future<String, Error> {
        return Future { promise in
            ConnectMeVcx().connectionSerialize(connectionHandle) { error, serializedConnection in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("connectionSerialize was successful!")
                    promise(.success(serializedConnection!))
                }
            }
        }
    }
    
    func connectionDeserialize(serializedConnection: String) -> Future<Int, Error> {
        return Future { promise in
            ConnectMeVcx().connectionDeserialize(serializedConnection) { error, connectionHandle in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("connectionDeserialize was successful!")
                    promise(.success(connectionHandle))
                }
            }
        }
    }
    
    func connectionRelease(connectionHandle: Int) -> Int {
        return Int(ConnectMeVcx().connectionRelease(connectionHandle))
    }
    
    func credentialGetOffers(connectionHandle: Int) -> Future<String, Error> {
        return Future { promise in
            ConnectMeVcx().credentialGetOffers(VcxHandle(truncatingIfNeeded: connectionHandle)) { error, offers in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("credentialGetOffers was successful!")
                    promise(.success(offers!))
                }
            }
        }
    }
    
    func credentialCreateWithOffer(sourceId: String, credentialOffer: String) -> Future<Int, Error> {
        return Future { promise in
            ConnectMeVcx().credentialCreate(withOffer: sourceId, offer: credentialOffer) { error, credentialHandle in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("credentialCreateWithOffer was successful!")
                    promise(.success(credentialHandle))
                }
            }
        }
    }
    
    func credentialSendRequest(credentialHandle: Int, connectionHandle: Int, paymentHandle: Int) -> Future<String, Error> {
        return Future { promise in
            ConnectMeVcx().credentialSendRequest(credentialHandle, connectionHandle: VcxHandle(truncatingIfNeeded: connectionHandle), paymentHandle: vcx_payment_handle_t(paymentHandle)) { error in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("credentialSendRequest was successful!")
                    promise(.success(""))
                }
            }
        }
    }
    
    func credentialUpdateState(credentialHandle: Int, connectionHandle: Int) -> Future<Int, Error> {
        return Future { promise in
            ConnectMeVcx().credentialUpdateStateV2(credentialHandle, connectionHandle: VcxHandle(truncatingIfNeeded: connectionHandle)) { error, state in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("credentialUpdateState was successful!")
                    promise(.success(state))
                }
            }
        }
    }
    
    func credentialGetState(credentialHandle: Int) -> Future<Int, Error> {
        return Future { promise in
            ConnectMeVcx().credentialGetState(credentialHandle) { error, state in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("credentialGetState was successful!")
                    promise(.success(state))
                }
            }
        }
    }
    
    func credentialSerialize(credentialHandle: Int) -> Future<String, Error> {
        return Future { promise in
            ConnectMeVcx().credentialSerialize(credentialHandle) { error, serializedCredential in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("credentialSerialize was successful!")
                    promise(.success(serializedCredential!))
                }
            }
        }
    }
    
    func credentialDeserialize(serializedCredential: String) -> Future<Int, Error> {
        return Future { promise in
            ConnectMeVcx().credentialDeserialize(serializedCredential) { error, credentialHandle in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("credentialDeserialize was successful!")
                    promise(.success(credentialHandle))
                }
            }
        }
    }
    
    func credentialRelease(credentialHandle: Int) -> Int {
        return Int(ConnectMeVcx().connectionRelease(credentialHandle))
    }
    
    func proofGetRequests(connectionHandle: Int) -> Future<String, Error> {
        return Future { promise in
            ConnectMeVcx().proofGetRequests(connectionHandle) { error, requests in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("proofGetRequests was successful!")
                    promise(.success(requests!))
                }
            }
        }
    }
    
    func proofCreateWithRequest(sourceId: String, proofRequest: String) -> Future<Int, Error> {
        return Future { promise in
            ConnectMeVcx().proofCreate(withRequest: sourceId, withProofRequest: proofRequest) { error, proofHandle in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("proofCreateWithRequest was successful!")
                    promise(.success(Int(proofHandle)))
                }
            }
        }
    }
    
    func proofRetrieveCredentials(proofHandle: Int) -> Future<String, Error> {
        return Future { promise in
            ConnectMeVcx().proofRetrieveCredentials(vcx_proof_handle_t(proofHandle)) { error, matchingCredentials in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("proofRetrieveCredentials was successful!")
                    promise(.success(matchingCredentials!))
                }
            }
        }
    }
    
    func proofGenerate(proofHandle: Int, selectedCredentials: String, selfAttestedAttrs: String) -> Future<String, Error> {
        return Future { promise in
            ConnectMeVcx().proofGenerate(vcx_proof_handle_t(proofHandle), withSelectedCredentials: selectedCredentials, withSelfAttestedAttrs: selfAttestedAttrs) { error in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("proofGenerate was successful!")
                    promise(.success(""))
                }
            }
        }
    }
    
    func proofSend(proofHandle: Int, connectionHandle: Int) -> Future<String, Error> {
        return Future { promise in
            ConnectMeVcx().proofSend(vcx_proof_handle_t(proofHandle), withConnectionHandle: vcx_connection_handle_t(connectionHandle)) { error in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("proofSend was successful!")
                    promise(.success(""))
                }
            }
        }
    }
    
    func proofUpdateState(proofHandle: Int, connectionHandle: Int) -> Future<Int, Error> {
        return Future { promise in
            ConnectMeVcx().proofUpdateStateV2(proofHandle, connectionHandle: vcx_connection_handle_t(connectionHandle)) { error, state in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("proofUpdateState was successful!")
                    promise(.success(state))
                }
            }
        }
    }
    
    func proofGetState(proofHandle: Int) -> Future<Int, Error> {
        return Future { promise in
            ConnectMeVcx().proofGetState(proofHandle) { error, state in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("proofGetState was successful!")
                    promise(.success(state))
                }
            }
        }
    }
    
    func proofSerialize(proofHandle: Int) -> Future<String, Error> {
        return Future { promise in
            ConnectMeVcx().proofSerialize(vcx_proof_handle_t(proofHandle)) { error, serializedProof in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("proofSerialize was successful!")
                    promise(.success(serializedProof!))
                }
            }
        }
    }
    
    func proofDeserialize(serializedProof: String) -> Future<Int, Error> {
        return Future { promise in
            ConnectMeVcx().proofDeserialize(serializedProof) { error, proofHandle in
                if error != nil && (error as NSError?)?.code != 0 {
                    promise(.failure(error!))
                } else {
                    print("proofDeserialize was successful!")
                    promise(.success(Int(proofHandle)))
                }
            }
        }
    }
    
    func proofRelease(proofHandle: Int) -> Int {
        return Int(ConnectMeVcx().proofRelease(proofHandle))
    }

}
