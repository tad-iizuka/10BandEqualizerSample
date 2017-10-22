//
//  ViewController.swift
//  EqualizerSample
//
//  Created by Tadashi on 2017/10/22.
//  Copyright © 2017 UBUNIFU Inc. All rights reserved.
//

import UIKit
import MediaPlayer

class ViewController: UIViewController {

	var audioEngine: AVAudioEngine!
	var audioPlayerNode: AVAudioPlayerNode!
	var audioFile: AVAudioFile!
	var audioUnitEQ = AVAudioUnitEQ(numberOfBands: 10)
	var isPlaying = false

	let MAX_GAIN: Float = 24.0
	let MIN_GAIN: Float = -96.0

	@IBOutlet weak var playButton: UIButton!
	@IBAction func play(_ sender: Any) {
		let button = sender as! UIButton
		button.isEnabled = false
		if self.isPlaying {
			self.audioStop()
			button.setTitle("PLAY", for: .normal)
		} else {
			self.audioPlay()
			button.setTitle("STOP", for: .normal)
		}
		button.isEnabled = true
	}
	
	@IBOutlet weak var bypassButton: UISwitch!
	@IBAction func bypass(_ sender: Any) {
		self.audioUnitEQ.bypass = !self.audioUnitEQ.bypass
	}
	
	@IBAction func gainChange(_ sender: Any) {
		let slider = sender as! UISlider
		let band = self.audioUnitEQ.bands[slider.tag]
		band.gain = slider.value
		let gain = self.value(forKey: String(format: "gain%d", slider.tag)) as! UILabel
		gain.text = String(format: "%.1f", band.gain)
	}

	@IBOutlet weak var eq0: UISlider!
	@IBOutlet weak var eq1: UISlider!
	@IBOutlet weak var eq2: UISlider!
	@IBOutlet weak var eq3: UISlider!
	@IBOutlet weak var eq4: UISlider!
	@IBOutlet weak var eq5: UISlider!
	@IBOutlet weak var eq6: UISlider!
	@IBOutlet weak var eq7: UISlider!
	@IBOutlet weak var eq8: UISlider!
	@IBOutlet weak var eq9: UISlider!

	@IBOutlet weak var gain0: UILabel!
	@IBOutlet weak var gain1: UILabel!
	@IBOutlet weak var gain2: UILabel!
	@IBOutlet weak var gain3: UILabel!
	@IBOutlet weak var gain4: UILabel!
	@IBOutlet weak var gain5: UILabel!
	@IBOutlet weak var gain6: UILabel!
	@IBOutlet weak var gain7: UILabel!
	@IBOutlet weak var gain8: UILabel!
	@IBOutlet weak var gain9: UILabel!

	override func viewDidLoad() {
		super.viewDidLoad()

		for i in 0...9 {
			let eq = self.value(forKey: String(format: "eq%d", i)) as! UISlider
			eq.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
			eq.setThumbImage(UIImage(named: "thumb-gray-20.png"), for: .normal)
			eq.setThumbImage(UIImage(named: "thumb-gray-50.png"), for: .highlighted)
			eq.maximumValue = MAX_GAIN
			eq.minimumValue = MIN_GAIN
			eq.alpha = 1
			eq.value = 0
		}
	}

	func audioSetup() {

		let FREQUENCY: [Float] = [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]

		self.audioEngine = AVAudioEngine.init()
		self.audioPlayerNode = AVAudioPlayerNode.init()
		self.audioUnitEQ = AVAudioUnitEQ(numberOfBands: 10)
		self.audioEngine.attach(self.audioPlayerNode)
		self.audioEngine.attach(self.audioUnitEQ)
		for i in 0...9 {
			self.audioUnitEQ.bands[i].filterType = .parametric
			self.audioUnitEQ.bands[i].frequency = FREQUENCY[i]
			self.audioUnitEQ.bands[i].bandwidth = 0.5 // half an octave
			let eq = self.value(forKey: String(format: "eq%d", i)) as! UISlider
			self.audioUnitEQ.bands[i].gain = eq.value
			self.audioUnitEQ.bands[i].bypass = false
		}
		self.audioUnitEQ.bypass = self.bypassButton.isOn
	}

	func audioPlay() {

		self.isPlaying = true

		try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
		try! AVAudioSession.sharedInstance().setActive(true)

		self.audioSetup()

		let path = Bundle.main.path(forResource: "toccata", ofType: "mp3")
		self.audioFile = try! AVAudioFile(forReading: URL(fileURLWithPath: path!))

		self.audioPlayerNode.scheduleSegment(self.audioFile, startingFrame: 0, frameCount: AVAudioFrameCount(self.audioFile.length), at: nil, completionHandler: self.completion)

		self.audioEngine.connect(self.audioPlayerNode, to: self.audioUnitEQ, format: self.audioFile.processingFormat)
		self.audioEngine.connect(self.audioUnitEQ, to: self.audioEngine.mainMixerNode, format: self.audioFile.processingFormat)

		if !self.audioEngine.isRunning {
			try! self.audioEngine.start()
		}
		let sampleRate = self.audioFile.processingFormat.sampleRate / 2
		let format = self.audioEngine.mainMixerNode.outputFormat(forBus: 0)
		self.audioEngine.mainMixerNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(sampleRate), format: format, block:{ (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
			// print(buffer.frameLength)
		})
		self.audioPlayerNode.play()
	}
	
	func audioStop() {
		self.isPlaying = false
		self.audioPlayerNode.pause()
		self.audioPlayerNode.stop()
		self.audioEngine.stop()
		self.audioEngine.mainMixerNode.removeTap(onBus: 0)
	}

	func completion() {
		if self.isPlaying {
			DispatchQueue.main.async {
				self.play(self.playButton)
			}
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}

