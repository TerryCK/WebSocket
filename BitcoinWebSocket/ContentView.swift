//
//  ContentView.swift
//  BitcoinWebSocket
//
//  Created by Terry Chen on 2021/11/30.
//

import SwiftUI
import Foundation
import Combine

class HomeViewModel: ObservableObject {
    private let webSocketTask: URLSessionWebSocketTask
    // The API Token can generator from
    //    https://finnhub.io/dashboard
    init(_ session: URLSession = .shared,
         url: URL = URL(string: "wss://ws.finnhub.io?token=APItoken")!) {
        webSocketTask = session
            .webSocketTask(with: url)
    }
    
    func send(msg: String) {
        webSocketTask.send(.string(msg)) { err in print(err?.localizedDescription ?? "") }
    }
    
    func registerAListener() {
        webSocketTask.receive { result in print(result) }
    }
    
    func disconnect() {
        webSocketTask.cancel(with: .goingAway, reason: nil)
    }
    
    func registerApingPong() {
        webSocketTask.sendPing { err in print(err?.localizedDescription ?? "")  }
    }
    
    
    private var subscriptions = Set<AnyCancellable>()
    
    func connect() {
        webSocketTask.resume()
        sendMessage()
        startListen()
    }
    
    private func sendMessage() {
        
        let string = "{\"type\":\"subscribe\",\"symbol\":\"BINANCE:BTCUSDT\"}"
        let message = URLSessionWebSocketTask.Message.string(string)
        webSocketTask.send(message) { error in
            if let error = error {
                print("WebSocket couldn’t send message because: \(error)")
            }
        }
    }
    
    @Published var priceResult: String = ""
    @Published private var socketPackage: String = ""
    
    private func startListen() {
        
        $socketPackage
            .filter { !$0.isEmpty }
            .map { Data($0.utf8) }
            .map { data in
                try? JSONDecoder().decode(APIResponse.self, from: data).data.first?.p
            }
            .debounce(for: 1, scheduler: DispatchQueue.main)
            .filter { $0 != nil }
            .replaceNil(with: Float(0))
            
            .map { String(describing: $0) }
            .print("socket")
            .removeDuplicates()
            .assign(to: \.priceResult, on: self)
            .store(in: &subscriptions)
        
        
        receive()
    }
    
    func receive() {
        webSocketTask.receive { [weak self] result in
            switch result {
            case let .success(.string(value)):
                DispatchQueue.main.async {
                    self?.socketPackage = value
                }
                self?.receive()
            case let .failure(err): print("Error in receiving message: \(err)")
            default:
                print("default in \(#function)")
            }
        }
    }
}


struct APIResponse: Codable {
    let data: [PriceData]
    var type : String
}
struct PriceData: Codable {
     let p: Float
}

struct ContentView: View {
    @StateObject var service = HomeViewModel()
    
    var body: some View {
        VStack{
            Image(systemName: "bitcoinsign.circle.fill")
                .font(.system(size: 150))
                .foregroundColor(Color(red: 247 / 255, green: 142 / 255, blue: 26 / 255))
                .padding()
            Text("USD")
                .font(.largeTitle)
                .padding()
            Text(service.priceResult)
                .font(.system(size: 60))
        }
        .onAppear(perform: service.connect)
        .onDisappear(perform: service.disconnect)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
