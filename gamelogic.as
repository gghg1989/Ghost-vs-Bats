import fl.transitions.Tween;
import fl.transitions.easing.*;
import fl.transitions.TweenEvent;
import flash.media.Sound;
import flash.net.SharedObject;

/**************变量**************/
var STATE_INIT_GAME:String = "STATE_INIT_GAME";
var STATE_START_PLAYER:String = "STATE_START_PLAYER";
var STATE_PLAY_GAME:String = "STATE_PLAY_GAME";
var STATE_END_GAME:String = "STATE_END_GAME";
var gameState:String;

var player:MovieClip;
var enemies:Array;
var level:Number;
var score:Number;
var lives:Number;
var accel:Accelerometer;
var Lasers:Array;
var explosions:Array;
var hiddenOptions:Boolean = true;
/**************开始**************/

endScreen.visible = false;
optionsMenu.visible = false;

/**************导入界面**************/

introScreen.play_btn.addEventListener(MouseEvent.CLICK, clickAway);
function clickAway(event:MouseEvent):void
{
	moveScreenOff(introScreen);
}
//功能函数
Multitouch.inputMode = MultitouchInputMode.GESTURE;
introScreen.addEventListener(TransformGestureEvent.GESTURE_SWIPE, swipeAway);
function swipeAway(event:TransformGestureEvent):void
{
	if (event.offsetX == -1)
	{
		moveScreenOff(introScreen);
	}
}


function moveScreenOff(screen:MovieClip):void
{
	//移出画面
	var introTween = new Tween(screen,"x",Strong.easeInOut,screen.x,(screen.width)*-1,1,true);
	introTween.addEventListener(TweenEvent.MOTION_FINISH, tweenFinish);
	function tweenFinish(e:TweenEvent):void
	{
		trace("tweenFinish");
		gameState = STATE_INIT_GAME;
		trace(gameState);
		addEventListener(Event.ENTER_FRAME, gameLoop);
	}
}

/**************游戏状态**************/
function gameLoop(e:Event):void
{
	switch (gameState)
	{
		case STATE_INIT_GAME :
			initGame();
			break;
		case STATE_START_PLAYER :
			startPlayer();
			break;
		case STATE_PLAY_GAME :
			playGame();
			break;
		case STATE_END_GAME :
			endGame();
			break;
	}
}


/**************初始化状态**************/
function initGame():void
{

	level = 1;
	level_txt.text = String(level);
	score = 0;
	score_txt.text = String(score);
	lives = 2;
	lives_txt.text = String(lives);

	player = new Player();
	
	enemies = new Array();
	
	Lasers = new Array();
	
	explosions = new Array();
	gameState = STATE_START_PLAYER;
	trace(gameState);

}

/**************初始化角色**************/
function startPlayer():void
{
	player.y = stage.stageHeight - player.height;
	player.cacheAsBitmap = true;
	addChild(player);
	
	laserTimer.start();
	
	accel = new Accelerometer();
	
	if (Accelerometer.isSupported)
	{
		
		accel.addEventListener(AccelerometerEvent.UPDATE, accelMove);
	}
	else
	{
		
		addEventListener(Event.ENTER_FRAME, movePlayer);
	}
	gameState = STATE_PLAY_GAME;
	trace(gameState);
}

function accelMove(event:AccelerometerEvent):void
{
	
	player.x -=  event.accelerationX * 80;
	if (player.x < 0)
	{
		player.x = 0;
	}
	else if (player.x > (stage.stageWidth - player.width) )
	{
		player.x = stage.stageWidth - player.width;
	}
}


function movePlayer(e:Event):void
{
	player.x = stage.mouseX;
	
	if (player.x < 0)
	{
		player.x = 0;
	}
	else if (player.x > (stage.stageWidth - player.width) )
	{
		player.x = stage.stageWidth - player.width;
	}
}


var laserTimer:Timer = new Timer(500);
laserTimer.addEventListener(TimerEvent.TIMER, timerListener);
function timerListener(e:TimerEvent):void
{
	
	var tempLaser:MovieClip = new Laser();
	
	tempLaser.x = player.x +(player.width/2);
	tempLaser.y = player.y;
	tempLaser.cacheAsBitmap = true;
	tempLaser.speed = 10;
	Lasers.push(tempLaser);
	addChild(tempLaser);
}


function moveLaser():void
{
	
	var tempLaser:MovieClip;
	for (var i=Lasers.length-1; i>=0; i--)
	{
		tempLaser = Lasers[i];
		
		tempLaser.y -=  tempLaser.speed;
		if (tempLaser.y < 0)
		{
			
			removeLaser(i);
		}
	}
	
	var tempExplosion:MovieClip;
	for (i=explosions.length-1; i>=0; i--)
	{
		tempExplosion = explosions[i];
		if (tempExplosion.currentFrame >= tempExplosion.totalFrames)
		{
			removeExplosion(i);
		}
	}
}


/**************开始游戏状态**************/
function playGame():void
{
	

	makeEnemies();
	moveEnemies();
	moveLaser();
	testForEnd();
}


function makeEnemies():void
{
	
	var chance:Number = Math.floor(Math.random() * 60);
	
	if (chance <= 1 + level)
	{
		var tempEnemy:MovieClip;
		
		tempEnemy = new Enemy();
		tempEnemy.speed = 3;
		
		tempEnemy.x = Math.round(Math.random() * 800);
		tempEnemy.cacheAsBitmapMatrix = tempEnemy.transform.concatenatedMatrix;
		tempEnemy.cacheAsBitmap = true;
		trace("tempEnemy");
		addChild(tempEnemy);
		enemies.push(tempEnemy);
	}
}

function moveEnemies():void
{
	var tempEnemy:MovieClip;
	for (var i:int =enemies.length-1; i>=0; i--)
	{
		tempEnemy = enemies[i];


		tempEnemy.rotation += (Math.round(Math.random()*10-5));
		
		tempEnemy.x -=  (Math.sin((Math.PI/180)*tempEnemy.rotation))*tempEnemy.speed;
		tempEnemy.y +=  (Math.cos((Math.PI/180)*tempEnemy.rotation))*tempEnemy.speed;
		if (tempEnemy.x < 0)
		{
			tempEnemy.x = 0;
		}
		if (tempEnemy.x > stage.stageWidth)
		{
			tempEnemy.x = stage.stageWidth;
		}
		if (tempEnemy.y > stage.stageHeight || tempEnemy.hitTestObject(player))
		{
			makeExplosion(tempEnemy.x, tempEnemy.y);
			
			removeEnemy(i);
			
			lives--;
			lives_txt.text = String(lives);
		}
		
		var tempLaser:MovieClip;
		tempEnemy = enemies[i];
		
		for (var j:int=Lasers.length-1; j>=0; j--)
		{
			tempLaser = Lasers[j];
			if (tempEnemy.hitTestObject(tempLaser))
			{
				makeExplosion(tempEnemy.x, tempEnemy.y);
				removeEnemy(i);
				removeLaser(j);
				score++;
				score_txt.text = String(score);
			}
		}
	}
}




function makeExplosion(ex:Number, ey:Number):void
{
	var tempExplosion:MovieClip;
	tempExplosion = new Explosion();
	tempExplosion.x = ex;
	tempExplosion.y = ey;
	addChild(tempExplosion);
	explosions.push(tempExplosion);
	var sound:Sound = new Explode();
	sound.play();
}

function testForEnd():void
{
	if (score > level * 10)
	{
		level++;
		level_txt.text = String(level);
	}
	if (lives == 0)
	{
		gameState = STATE_END_GAME;
		trace(gameState);
	}
}

function removeEnemy(idx:int)
{
	removeChild(enemies[idx]);
	enemies.splice(idx,1);
}


function removeLaser(idx:int)
{
	removeChild(Lasers[idx]);
	Lasers.splice(idx,1);
}

function removeExplosion(idx:int)
{
	removeChild(explosions[idx]);
	explosions.splice(idx,1);
}

/**************游戏结束画面**************/
function endGame():void
{
	removeGame();
	endScreen.visible = true;
	removeEventListener(Event.ENTER_FRAME, gameLoop);
	showResults();
}
/**************移除游戏**************/
function removeGame():void
{
	trace("Remove Game");
	for (var i:int = enemies.length-1; i >=0; i--)
	{
		removeEnemy(i);
	}
	for (var j:int = Lasers.length-1; j >=0; j--)
	{
		removeLaser(j);
	}
	for (var k:int = explosions.length-1; k >=0; k--)
	{
		removeExplosion(k);
	}
	removeChild(player);
	laserTimer.stop();
}


function showResults():void
{
	trace("Show Results");
	endScreen.enter_btn.visible = false;
	endScreen.highScoreName.visible = false;
	var so:SharedObject = SharedObject.getLocal("alltimeHighScore");
	if (so.data.score == undefined || score > so.data.score)
	{
		endScreen.highScore.text = "您打到了第 " + level + " 关，得分为： " + score + "！ \n 在下面输入您的名字。";
		endScreen.enter_btn.visible = true;
		endScreen.highScoreName.visible = true;
	}
	else
	{
		
		endScreen.highScore.text = "您的得分为 " + score + " ，没能打破由" + so.data.name + "创造的" + so.data.score + "分记录。";
	}
	
	endScreen.enter_btn.addEventListener(MouseEvent.CLICK, clickEnter);
	function clickEnter(event:MouseEvent):void
	{
		trace("clickEnter");
		endScreen.highScore.text = "太棒了, " + endScreen.highScoreName.text + "! \n 你打到了第" + level + "关，得分为" + score + "!";
		
		so.data.score = score;
		so.data.level = level;
		so.data.name = endScreen.highScoreName.text;
		so.flush();
		
		endScreen.enter_btn.visible = false;
		endScreen.highScoreName.visible = false;
	}
	
	endScreen.play_btn.addEventListener(MouseEvent.CLICK, clickFinalAway);
	function clickFinalAway(event:MouseEvent):void
	{
		trace("clickFinalAway");
		moveScreenOff(endScreen);
	}
}

/**************菜单**************/
stage.addEventListener(KeyboardEvent.KEY_UP, optionsKey);
function optionsKey(event:KeyboardEvent):void
{
	if (event.keyCode == 95 || event.keyCode == 13)
	{
		if (hiddenOptions)
		{
			setChildIndex(optionsMenu,numChildren-1);
			optionsMenu.visible = true;
			optionsMenu.addEventListener(MouseEvent.CLICK, exitApp);
			pauseGame();
		}
		else
		{
			optionsMenu.visible = false;
			optionsMenu.removeEventListener(MouseEvent.CLICK, exitApp);
			resumeGame();
		}
		hiddenOptions = ! hiddenOptions;
	}
}

function exitApp(event:MouseEvent):void
{
	trace("exitApp");
}

stage.addEventListener(Event.DEACTIVATE, Deactivate);
function Deactivate(event:Event):void
{
	pauseGame();
}
stage.addEventListener(Event.ACTIVATE, Activate);
function Activate(event:Event):void
{
	resumeGame();
}

function pauseGame():void
{
	if (gameState == STATE_PLAY_GAME)
	{
		removeEventListener(Event.ENTER_FRAME, gameLoop);
		laserTimer.stop();
		accel.removeEventListener(AccelerometerEvent.UPDATE, accelMove);
	}
}

function resumeGame():void
{
	if (gameState == STATE_PLAY_GAME)
	{
		addEventListener(Event.ENTER_FRAME, gameLoop);
		laserTimer.start();
		accel.addEventListener(AccelerometerEvent.UPDATE, accelMove);
	}
}