//
//  DavinciViewModel.swift
//  PingExample
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import PingDavinci
import PingOidc
import PingOrchestrate
import PingLogger
import PingStorage
import PingExternal_idp

/// Configures and initializes the DaVinci instance with the PingOne server and OAuth 2.0 client details.
/// - This configuration includes:
///   - Client ID
///   - Scopes
///   - Redirect URI
///   - Discovery Endpoint
///   - Other optional fields
public let davinci = DaVinci.createDaVinci { config in
  //TODO: Provide here the Server configuration. Add the PingOne server Discovery Endpoint and the OAuth2.0 client details
  config.module(OidcModule.config) { oidcValue in
    oidcValue.clientId = "c98a2eaf-483d-469c-9990-1cc8e1142f02"
      oidcValue.scopes = ["email", "address", "openid", "phone", "profile"]
    oidcValue.redirectUri = "org.forgerock.demo://oauth2redirect"
    oidcValue.discoveryEndpoint = "https://auth.pingone.com/4b69e4ad-03bd-4203-89bb-0504221d9a1c/as/.well-known/openid-configuration"
    oidcValue.additionalParameters = ["favColor":"blue"]

  }
}

// A view model that manages the flow and state of the DaVinci orchestration process.
/// - Responsible for:
///   - Starting the DaVinci flow
///   - Progressing to the next node in the flow
///   - Maintaining the current and previous flow state
///   - Handling loading states
class DavinciViewModel: ObservableObject {
    /// Published property that holds the current state node data.
    @Published public var state: DavinciState = DavinciState()
    /// Published property to track whether the view is currently loading.
    @Published public var isLoading: Bool = false
    
    /// Initializes the view model and starts the DaVinci orchestration process.
    init() {
        Task {
            await startDavinci()
        }
    }
    
    /// Starts the DaVinci orchestration process.
    /// - Sets the initial node and updates the `data` property with the starting node.
    public func startDavinci() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Starts the DaVinci orchestration process and retrieves the first node.
        let next = await davinci.start()
        if let successNode = next as? SuccessNode {
            ConfigurationManager.shared.currentUser = successNode.user
        }
        await MainActor.run {
            self.state = DavinciState(previous: next , node: next)
            isLoading = false
        }
    }
    
    /// Advances to the next node in the orchestration process.
    /// - Parameter node: The current node to progress from.
    public func next(node: Node) async {
        await MainActor.run {
            isLoading = true
        }
        if let current = node as? ContinueNode {
            // Retrieves the next node in the flow.
            let next = await current.next()
            if let successNode = next as? SuccessNode {
                ConfigurationManager.shared.currentUser = successNode.user
            }
            await MainActor.run {
                self.state = DavinciState(previous: current, node: next)
                isLoading = false
            }
        }
    }
    
    public func shouldValidate(node: ContinueNode) -> Bool {
        var shouldValidate = false
        for collector in node.collectors {
<<<<<<< HEAD
            // Check if the collector is a social collector and if it has a resume request.
            // In that case, we should not validate the collectors and continue with the submission of the flow.
            if let socialCollector = collector as? IdpCollector {
                if socialCollector.resumeRequest != nil {
                    shouldValidate = false
                    return shouldValidate
                }
            }
=======
>>>>>>> 4f17bd6 (Changed colors for Social Login for All Hands Company call.)
            if let collector = collector as? ValidatedCollector {
                if collector.validate().count > 0 {
                    shouldValidate = true
                }
            }
        }
        return shouldValidate
    }
    
    public func refresh() {
        state = DavinciState(previous: state.previous, node: state.node)
    }
}

/// A model class that represents the state of the current and previous nodes in the DaVinci flow.
class DavinciState {
    var previous: Node? = nil
    var node: Node? = nil
    
    init(previous: Node?  = nil, node: Node? = nil) {
        self.previous = previous
        self.node = node
    }
}


public class ValidationViewModel: ObservableObject {
    @Published var shouldValidate = false
}
