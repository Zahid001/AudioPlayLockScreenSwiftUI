//
//  ContentView.swift
//  AudioLockScreenControl
//
//  Created by Md Zahidul Islam Mazumder on 16/9/20.
//  Copyright © 2020 Md Zahidul Islam Mazumder. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var audioHadler = AudioHandler()
    var body: some View {
        VStack{
           Text("Hello, World!")
        }.onAppear(){
            self.audioHadler.setUpPlayer()
            self.audioHadler.setupRemoteTransportControls()
            self.audioHadler.setupNowPlaying()
            self.audioHadler.setupNotifications()
            self.audioHadler.play()
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
