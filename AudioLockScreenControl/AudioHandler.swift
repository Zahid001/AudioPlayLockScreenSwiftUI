//
//  AudioHandler.swift
//  AudioLockScreenControl
//
//  Created by Md Zahidul Islam Mazumder on 16/9/20.
//  Copyright © 2020 Md Zahidul Islam Mazumder. All rights reserved.
//


import Foundation
import SwiftUI
import AVFoundation
import MediaPlayer

class AudioHandler: NSObject, ObservableObject, AVAudioPlayerDelegate {
    let group = DispatchGroup()
    var audioPlayer: AVAudioPlayer!
    @Published var isPlaying: Bool = true
    @Published var track = 0
 
   // var player = AVAudioPlayer()
    var player: AVAudioPlayer!
    
    var myAudioPlayer = AVAudioPlayer()
    var fileName = ""

    override init() {
        super.init()
       
    }

    func playSound(urlString: String?){
        
        //group.enter()
        //isPlaying = true
        guard let url = URL(string: urlString ?? "https://cdn.alquran.cloud/media/audio/ayah/ar.alafasy/3506") else {
                   print("Invalid URL")
                   return
               }
               do {
                   let session = AVAudioSession.sharedInstance()
                   try session.setCategory(AVAudioSession.Category.playback)
                   let soundData = try Data(contentsOf: url)
                   audioPlayer = try AVAudioPlayer(data: soundData)
                   audioPlayer.prepareToPlay()
                   //audioPlayer.volume = 0.7
                   //audioPlayer.delegate = self
                   let minuteString = String(format: "%02d", (Int(audioPlayer.duration) / 60))
                   let secondString = String(format: "%02d", (Int(audioPlayer.duration) % 60))
                   print("TOTAL TIMER: \(minuteString):\(secondString)")
                 
                   audioPlayer.play()
                
                  // self.group.leave()
                audioPlayer.delegate = self
               } catch {
                   print(error)
               }
    }
    
    
    func playAudio() {
        let path = Bundle.main.path(forResource: fileName, ofType:nil)!
        let url = URL(fileURLWithPath: path)

        do {
            myAudioPlayer = try AVAudioPlayer(contentsOf: url)
            myAudioPlayer.play()
        } catch {
            // couldn't load file :(
        }
    }

//    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
//        print("Did finish Playing")
//        isPlaying = false
//
//        //playSound(urlString: self.detailsOfSurahModel.arabicTranslate[2].audio)
//
//        //track += 1
//
//        //isPlaying = true
//    }
}


extension AudioHandler{
    
    func setUpPlayer() {
        guard let url = URL(string:  "https://cdn.alquran.cloud/media/audio/ayah/ar.alafasy/3506") else {
            print("Invalid URL")
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(AVAudioSession.Category.playback)
            let soundData = try Data(contentsOf: url)
            player = try AVAudioPlayer(data: soundData)
            player.delegate = self
              player.prepareToPlay()
            } catch let error as NSError {
              print("Failed to init audio player: \(error)")
            }
            
            
           
        
    }
    
    /*
    func setUpPlayer() {
      do {
        let url = Bundle.main.url(forResource: "song", withExtension: "mp3")
        player = try AVAudioPlayer(contentsOf: url!)
        player.delegate = self
        player.prepareToPlay()
      } catch let error as NSError {
        print("Failed to init audio player: \(error)")
      }
    }
    */
    func setupRemoteTransportControls() {
      // Get the shared MPRemoteCommandCenter
      let commandCenter = MPRemoteCommandCenter.shared()
      
      // Add handler for Play Command
      commandCenter.playCommand.addTarget { [unowned self] event in
        print("Play command - is playing: \(self.player.isPlaying)")
        if !self.player.isPlaying {
          self.play()
          return .success
        }
        return .commandFailed
      }
      
      // Add handler for Pause Command
      commandCenter.pauseCommand.addTarget { [unowned self] event in
        print("Pause command - is playing: \(self.player.isPlaying)")
        if self.player.isPlaying {
          self.pause()
          return .success
        }
        return .commandFailed
      }
        
        commandCenter.nextTrackCommand.addTarget {  [unowned self] event in
            print("next")
            return .commandFailed
        }
    }
    
    func setupNowPlaying() {
      // Define Now Playing Info
      var nowPlayingInfo = [String : Any]()
      nowPlayingInfo[MPMediaItemPropertyTitle] = "Unstoppable"
      
      if let image = UIImage(named: "artist") {
        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in
          return image
        }
      }
      nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
      nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.duration
      nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
      
      // Set the metadata
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func updateNowPlaying(isPause: Bool) {
      // Define Now Playing Info
      var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo!
      
      nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
      nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPause ? 0 : 1
      
      // Set the metadata
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func setupNotifications() {
      let notificationCenter = NotificationCenter.default
      notificationCenter.addObserver(self,
                                     selector: #selector(handleInterruption),
                                     name: AVAudioSession.interruptionNotification,
                                     object: nil)
      notificationCenter.addObserver(self,
                                     selector: #selector(handleRouteChange),
                                     name: AVAudioSession.routeChangeNotification,
                                     object: nil)
    }
    
    // MARK: Handle Notifications
    @objc func handleRouteChange(notification: Notification) {
      guard let userInfo = notification.userInfo,
        let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
        let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue) else {
          return
      }
      switch reason {
      case .newDeviceAvailable:
        let session = AVAudioSession.sharedInstance()
        for output in session.currentRoute.outputs where output.portType == AVAudioSession.Port.headphones {
          print("headphones connected")
          DispatchQueue.main.sync {
            self.play()
          }
          break
        }
      case .oldDeviceUnavailable:
        if let previousRoute =
          userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
          for output in previousRoute.outputs where output.portType == AVAudioSession.Port.headphones {
            print("headphones disconnected")
            DispatchQueue.main.sync {
              self.pause()
            }
            break
          }
        }
      default: ()
      }
    }
    
    @objc func handleInterruption(notification: Notification) {
      guard let userInfo = notification.userInfo,
        let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
        let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
          return
      }
      
      if type == .began {
        print("Interruption began")
        // Interruption began, take appropriate actions
      }
      else if type == .ended {
        if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
          let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
          if options.contains(.shouldResume) {
            // Interruption Ended - playback should resume
            print("Interruption Ended - playback should resume")
            play()
          } else {
            // Interruption Ended - playback should NOT resume
            print("Interruption Ended - playback should NOT resume")
          }
        }
      }
    }
    
    

    func play() {
      player.play()
     // playPauseButton.setTitle("Pause", for: UIControl.State.normal)
      updateNowPlaying(isPause: false)
      print("Play - current time: \(player.currentTime) - is playing: \(player.isPlaying)")
    }
    
    func pause() {
      player.pause()
      //playPauseButton.setTitle("Play", for: UIControl.State.normal)
      updateNowPlaying(isPause: true)
      print("Pause - current time: \(player.currentTime) - is playing: \(player.isPlaying)")
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
      print("Audio player did finish playing: \(flag)")
      if (flag) {
        updateNowPlaying(isPause: true)
       // playPauseButton.setTitle("Play", for: UIControl.State.normal)
      }
    }
}
