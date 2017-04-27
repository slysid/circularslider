# circularslider
Circular Slider Audio Player - Swift 3.0

Introduction

CircularSlider provides a circlualr audio player slider UI component for iOS 9.0 & above written in Swift 3.0. Player controls are NOT included in this project and you have to design your own controls and call corresponding methods on controller action. The circular arc is 270 degrees. Not tested for other degress

Sample Code:

How to initalize circularslider view:

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sliderView = CircularSlider(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        self.sliderView!.center = CGPoint(x: self.view.frame.size.width * 0.25, y: 150)
        self.sliderView!.circularSliderDelegate = self
        self.view.addSubview(self.sliderView!)
     }
     
Editable/Skinnable Properties:

    property   : sliderLineWidth
    type       : CGFloat 
    description: sets the line width of the slider arc

    property   : sliderStrokeColor
    type       : UIColor 
    description: sets the bgclolor for arc

    property   : knobRadius
    type       : CGFloat 
    description: radius of slider knob

    property   : knobFillColor
    type       : UIColor 
    description: knob color over arc

    property   : playerStatus
    type       : AudioPlayerStatus. 
    description: Enum with values .play, .stopped, .paused. Status of the audio player can be retrieved or set if needed

    property   : avatar
    type       : UIImageView 
    description: can set a image inside the slider arc

    property   : title
    type       : UILabel 
    description: can set a a text bottom to arc


Public Methods:

      signature: play(duration:Int, data:Data)
      description: plays given data animates the circular slider accordingly.
  
      signature: stop()
      description: stops the player
  
      signature: pause()
      description: pauses the player
  
      signature: reset()
      description: reset all properties to original value


Example Usage:
        
        self.sliderView = CircularSlider(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        self.addSubview(self.sliderView!)
        
        //To Play
        self.sliderView!.play(duration: 60, data: self.voiceData!)
        
        // To Stop
        self.sliderView!.stop()
        
        // To Pause
        self.sliderView!.pause()
        
        To unpause call play method
        
Delegate Methods

Exposes a delegate called "circularSliderDelegate" and class must conform to "circularSliderDelegate" protocol methods. They providing real time status of the player and control can be animated accordingly

    func playerStartedPlayingContent()
    func playerStoppedPlayingContent() -> Called when user stops the player
    func playerPausedPlayingContent()
    func playerUnpausedPlayingContent()
    func playerFinishedPlayingContent() -> Called when player stops itself


    
