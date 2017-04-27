//
//  CircularSliderPlayer.swift
//
//  Created by Bharath on 2017-04-25.
//  Copyright © 2017 Bharath. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

protocol CircularSliderProtocols {
    
    func playerStartedPlayingContent()
    func playerStoppedPlayingContent()
    func playerPausedPlayingContent()
    func playerUnpausedPlayingContent()
    func playerFinishedPlayingContent()
    
}

enum AudioPlayerStatus {
    
    case stopped
    case play
    case paused
}

class TimerLabel:UILabel {
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        self.textAlignment = .center
        self.textColor = UIColor.black
        self.font = UIFont(name: "Arial", size:13.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CircularSlider:UIView {
    
    private let startAngle:CGFloat = 0.785
    private let endAngle:CGFloat = 2.357
    private var playDuration:Int = 0
    private var playAngleIncrementer:CGFloat = 0
    private var playAngle:CGFloat = 0
    private var playTimer:Timer?
    private var sliderTimer:Timer?
    public var playerStatus:AudioPlayerStatus = .stopped
    
    public var sliderLineWidth:CGFloat = 2.0
    public var sliderStrokeColor:UIColor = UIColor.red
    private var sliderRadius:CGFloat = 0.0
    private var sliderCenter:CGPoint = CGPoint(x: 0, y: 0)
    
    
    public var knobRadius:CGFloat = 10.0
    public var knobFillColor:UIColor = UIColor.red
    private var knobCenter:CGPoint = CGPoint(x: 50, y: 50)
    private var isKnobTouched:Bool = false
    private var knobAngle:CGFloat = -0.785
    
    public var avatar:UIImageView?
    private var minTimeLabel:TimerLabel?
    private var maxTimeLabel:TimerLabel?
    public var title:TimerLabel?
    private var minValue:Int = 0
    private var maxValue:Int = 0
    
    private var audioPlayer:AVAudioPlayer?
    public var circularSliderDelegate:CircularSliderProtocols?
    
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        self.isUserInteractionEnabled = true
        
        self.setCenterPoint(rect: frame)
        self.addAvatar()
        self.addTimeLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        
        self.setKnobCenter(radianAngle: self.knobAngle)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(self.sliderLineWidth)
        context?.setStrokeColor(self.sliderStrokeColor.cgColor)
        context?.setFillColor(self.knobFillColor.cgColor)
        context?.addArc(center:sliderCenter, radius: sliderRadius, startAngle:self.startAngle , endAngle:self.endAngle, clockwise: true)
        context?.strokePath()
        
        context?.addArc(center: self.knobCenter, radius:self.knobRadius, startAngle: 0, endAngle: (3.14 * 2), clockwise: false)
        context?.fillPath()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesBegan(touches, with: event)
        
        let touch = touches.first
        let touchPoint = touch?.location(in: self)
        
        let xDelta = touchPoint!.x - self.knobCenter.x
        let yDelta = touchPoint!.y - self.knobCenter.y
        let radius = sqrtf(Float((xDelta * xDelta) + (yDelta + yDelta)))
        
        if (CGFloat(radius) <= knobRadius) {
            
            self.isKnobTouched = true
        }
        else {
            
            self.isKnobTouched = false
        }
        
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesMoved(touches, with: event)
        
        
        if (self.isKnobTouched == true) {
            
            if(self.sliderTimer != nil) {
                
                self.sliderTimer!.invalidate()
                self.sliderTimer = nil
            }
            
            let touch = touches.first
            let touchPoint = touch?.location(in: self)
            
            let vectorA = CGPoint(x: (self.sliderCenter.x - touchPoint!.x), y: (self.sliderCenter.y - touchPoint!.y))
            
            self.knobAngle = atan2(vectorA.x,vectorA.y)
            self.knobAngle = CGFloat(Double.pi * 0.5) - self.knobAngle
            
            if (self.knobAngle >= -self.startAngle && self.knobAngle <= (self.endAngle + 1.57)) {
                
                self.setNeedsDisplay()
                
            }
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesEnded(touches, with: event)
        
        if (self.knobAngle < -self.startAngle) {
            
            self.knobAngle = -self.startAngle
        }
        else if(self.knobAngle > (self.endAngle + 1.57)) {
            
            self.knobAngle = self.endAngle + 1.57
        }
        
        
        if (self.knobAngle >= -self.startAngle && self.knobAngle <= (self.endAngle + 1.57) && self.playerStatus == .play) {
            
            self.startSliderTimer()
            self.minValue = self.getSecondsForKnobAngle(radianAngle: self.knobAngle)
            self.maxValue = self.playDuration - self.minValue
            self.updateTimeLabelsWith(min: self.minValue, max: self.maxValue)
            
            if (TimeInterval(self.minValue) < self.audioPlayer!.duration && TimeInterval(self.minValue) > 0) {
                self.audioPlayer!.currentTime = TimeInterval(self.minValue)
            }
        }
        
    }
    
    
    // PRIVATE METHODS
    
    private func addAvatar() {
        
        let frm = self.bounds.insetBy(dx:20, dy:20)
        self.avatar = UIImageView(frame: frm)
        self.avatar!.layer.cornerRadius = frm.size.width * 0.5
        self.avatar!.clipsToBounds = true
        self.avatar!.backgroundColor = UIColor.clear
        self.addSubview(self.avatar!)
    }
    
    private func addTimeLabel() {
        
        let timeLabelWidth:CGFloat = 55.0
        let timeLabelHeight:CGFloat = 25.0
        
        self.minTimeLabel = TimerLabel(frame:CGRect(x: 0, y: self.bounds.size.height - timeLabelHeight, width: timeLabelWidth, height: timeLabelHeight))
        self.addSubview(self.minTimeLabel!)
        
        self.maxTimeLabel = TimerLabel(frame:CGRect(x:self.bounds.size.width - timeLabelWidth, y: self.minTimeLabel!.frame.origin.y , width: timeLabelWidth, height: timeLabelHeight))
        self.addSubview(self.maxTimeLabel!)
        
        let width = self.maxTimeLabel!.frame.origin.x - (self.minTimeLabel!.frame.origin.x + self.minTimeLabel!.frame.size.width)
        self.title = TimerLabel(frame: CGRect(x: self.minTimeLabel!.frame.size.width, y: self.minTimeLabel!.frame.origin.y, width: width, height: self.minTimeLabel!.frame.size.height))
        self.addSubview(self.title!)
        
        self.updateTimeLabelsWith(min: 0, max: 0)
        
    }
    
    
    private func getAPointOnArc(radianAngle:CGFloat) -> CGPoint {
        
        let dx = self.sliderCenter.x - (self.sliderRadius * cos(radianAngle))
        let dy = self.sliderCenter.y - (self.sliderRadius * sin(radianAngle))
        
        return CGPoint(x: dx, y: dy)
    }
    
    private func setCenterPoint(rect:CGRect) {
        
        if (self.sliderRadius == 0.0) {
            
            self.sliderRadius = rect.size.width * 0.5 - self.knobRadius
        }
        
        self.sliderCenter = CGPoint(x: self.sliderRadius + self.knobRadius, y: self.sliderRadius + self.knobRadius)
        
    }
    
    private func setKnobCenter(radianAngle:CGFloat) {
        
        self.knobCenter = self.getAPointOnArc(radianAngle: self.knobAngle)
    }
    
    
    @objc private func updateTimeLabels() {
        
        self.minValue = self.minValue + 1
        self.maxValue = self.maxValue - 1
        self.updateTimeLabelsWith(min: self.minValue, max: self.maxValue)
        
        if (minValue >= self.playDuration) {
            
            self.playTimer?.invalidate()
            self.playTimer = nil
            
            self.sliderTimer?.invalidate()
            self.sliderTimer = nil
            
            self.playerStatus = .stopped
            
            self.minValue = 0
            self.maxValue = self.playDuration
            
            if (self.circularSliderDelegate != nil) {
                
                self.circularSliderDelegate!.playerFinishedPlayingContent()
            }
        }
    }
    
    @objc private func moveKnobByAngle() {
        
        self.knobAngle = self.knobAngle + self.playAngleIncrementer
        self.setNeedsDisplay()
        
    }
    
    private func secondsToMsSs(_ seconds : Int) -> String {
        
        let minutes = timeText((seconds % 3600) / 60)
        let seconds =  timeText((seconds % 3600) % 60)
        
        return "\(minutes):\(seconds)"
    }
    
    private func timeText(_ s: Int) -> String {
        
        return s < 10 ? "0\(s)" : "\(s)"
    }
    
    
    private func updateTimeLabelsWith(min:Int,max:Int) {
        
        self.minTimeLabel!.text = self.secondsToMsSs(self.minValue)
        self.maxTimeLabel!.text = self.secondsToMsSs(self.maxValue)
    }
    
    private func startSliderTimer() {
        
        if (self.sliderTimer == nil) {
            
            self.sliderTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(moveKnobByAngle), userInfo: nil, repeats: true)
        }
    }
    
    private func getSecondsForKnobAngle(radianAngle:CGFloat) -> Int {
        
        let knobPoint = self.getAPointOnArc(radianAngle: self.knobAngle)
        let knobVector = CGPoint(x:(knobPoint.x - self.sliderCenter.x ), y:(knobPoint.y - self.sliderCenter.y))
        let referencePoint = self.getAPointOnArc(radianAngle: -self.startAngle)
        let referenceVector = CGPoint(x:(referencePoint.x - self.sliderCenter.x), y:(referencePoint.y - self.sliderCenter.y))
        
        var angle = atan2(knobVector.y, knobVector.x) - atan2(referenceVector.y, referenceVector.x)
        
        if (angle < 0) {
            
            angle = angle + (2 * CGFloat.pi)
        }
        
        let duration = Int((angle/self.playAngleIncrementer) / 100)
        return duration
    }
    
    private func startPlayTimer() {
        
        if (self.playTimer == nil) {
            
            self.playTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimeLabels), userInfo: nil, repeats: true)
        }
    }
    
    private func setPlayDuration(duration:Int) {
        
        self.playDuration = duration
        
        self.updateTimeLabelsWith(min:0, max: duration)
        self.minValue = 0
        self.maxValue = duration
        self.knobAngle = -self.startAngle
        self.playAngleIncrementer =  4.71239 / (CGFloat(duration) * 100)
    }
    
    // Public Methods
    
    public func play(duration:Int, data:Data) {
        
        
        if (self.playerStatus == .stopped) {
            
            self.setPlayDuration(duration: duration)
            if (self.circularSliderDelegate != nil) {
                
                self.circularSliderDelegate!.playerStartedPlayingContent()
            }
        }
        else if (self.playerStatus == .paused) {
            
            if (self.circularSliderDelegate != nil) {
                
                self.circularSliderDelegate!.playerUnpausedPlayingContent()
            }
        }
        
        self.startPlayTimer()
        self.startSliderTimer()
        self.playerStatus = .play
        if (self.audioPlayer == nil) {
            
            self.audioPlayer = try? AVAudioPlayer(data: data)
        }
        
        if (self.audioPlayer!.prepareToPlay() == true) {
            
            self.audioPlayer!.play(atTime: self.audioPlayer!.deviceCurrentTime + 0.1)
        }
        
    }
    
    public func stop() {
        
        if (self.playTimer != nil) {
            
            self.playTimer?.invalidate()
            self.playTimer = nil
        }
        
        if (self.sliderTimer != nil) {
            
            self.sliderTimer?.invalidate()
            self.sliderTimer = nil
            
        }
        
        self.audioPlayer!.stop()
        self.audioPlayer!.currentTime = TimeInterval(0)
        self.knobAngle = -self.startAngle
        self.playerStatus = .stopped
        self.minValue = 0
        self.maxValue = self.playDuration
        self.updateTimeLabelsWith(min: self.minValue, max: self.maxValue)
        self.setNeedsDisplay()
        
        if (self.circularSliderDelegate != nil) {
            
            self.circularSliderDelegate!.playerStoppedPlayingContent()
        }
    }
    
    public func pause() {
        
        if (self.playTimer != nil) {
            
            self.playTimer?.invalidate()
            self.playTimer = nil
        }
        
        if (self.sliderTimer != nil) {
            
            self.sliderTimer?.invalidate()
            self.sliderTimer = nil
            
        }
        
        self.playerStatus = .paused
        self.audioPlayer!.stop()
        
        if (self.circularSliderDelegate != nil) {
            
            self.circularSliderDelegate!.playerPausedPlayingContent()
        }
        
    }
    
    public func reset() {
        
        self.audioPlayer!.stop()
        self.minValue = 0
        self.maxValue = self.playDuration
        self.knobAngle = -self.startAngle
        self.playTimer?.invalidate()
        self.playTimer = nil
        self.sliderTimer?.invalidate()
        self.sliderTimer = nil
        self.updateTimeLabelsWith(min: 0, max: 0)
    }
    
}
