import UIKit
import AVFoundation
import Elm

//    typealias Message = AudioBarModule.Message
typealias Model = AudioBarModule.Model
typealias View = AudioBarModule.View
//    typealias Command = AudioBarModule.Command

class AudioBarViewController: UIViewController {

    typealias Module = AudioBarModule
    let program = Module.makeProgram()

    let player = AVPlayer()

    @IBOutlet var playPauseButton: UIButton!
    @IBOutlet var seekBackButton: UIButton!
    @IBOutlet var seekForwardButton: UIButton!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var audioRouteView: UIView!

    @IBAction func userDidTapPlayPauseButton() {
        program.dispatch(.togglePlay)
    }

    @IBAction func userDidTapSeekForwardButton() {
        program.dispatch(.seekForward)
    }

    @IBAction func userDidTapSeekBackButton() {
        program.dispatch(.seekBack)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        program.setDelegate(self)

        let url = URL(string: "http://www.healerslibrary.com/audiobook/english/The_Emotion_Code_Ch_1.mp3")!
        program.dispatch(.prepareToLoad(url))
        
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if let playerItem = player.currentItem, keyPath == #keyPath(AVPlayerItem.duration) {
            guard change![.oldKey] as! NSValue != change![.newKey] as! NSValue else { return }
            program.dispatch(.setDuration(playerItem.duration.timeInterval))
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

}

extension AudioBarViewController: ElmDelegate {

    func program(_ program: Program<Module>, didUpdate view: Module.View) {

        playPauseButton.setTitle(view.playPauseButtonMode.title, for: .normal)
        playPauseButton.isEnabled = view.isPlayPauseButtonEnabled

        seekBackButton.isHidden = view.areSeekButtonsHidden
        seekBackButton.isEnabled = view.isSeekBackButtonEnabled

        seekForwardButton.isHidden = view.areSeekButtonsHidden
        seekForwardButton.isEnabled = view.isSeekForwardButtonEnabled

        timeLabel.text = view.playbackTime

    }

    func program(_ program: Program<Module>, didEmit command: Module.Command) {

        switch command {
        case .player(let command):
            switch command {

            case .open(let url):
                let playerItem = AVPlayerItem(url: url)
                playerItem.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration), options: [.old, .new], context: nil)
                player.replaceCurrentItem(with: playerItem)
                player.addPeriodicTimeObserver(forInterval: CMTime(timeInterval: 0.1), queue: nil) { time in
                    program.dispatch(.setCurrentTime(time.timeInterval))
                }

            case .play:
                player.play()

            case .pause:
                player.pause()

            case .setCurrentTime(let time):
                player.setTime(time)
                
            }
        }
        
    }

}

extension AudioBarModule.View.PlayPauseButtonMode {

    var title: String {
        switch self {
        case .play: return "PL"
        case .pause: return "PA"
        }
    }
    
}

extension AVPlayer {

    var duration: TimeInterval {
        guard let currentItem = currentItem else { return 0 }
        return currentItem.duration.timeInterval
    }

    func setTime(_ time: TimeInterval) {
        let mediaTime = CMTime(timeInterval: time)
        seek(to: mediaTime)
    }

    var time: TimeInterval {
        return currentTime().timeInterval
    }

}

extension CMTime {

    init(timeInterval: TimeInterval) {
        self = CMTime(seconds: timeInterval, preferredTimescale: 44100)
    }

    var timeInterval: TimeInterval {
        return CMTimeGetSeconds(self)
    }

}
