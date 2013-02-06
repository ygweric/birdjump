#import "Game.h"
#import "Main.h"
#import "Highscores.h"

@interface Game (Private)
- (void)initPlatforms;
- (void)initPlatform;
- (void)startGame;
- (void)resetPlatforms;
- (void)resetPlatform;
- (void)resetBird;
- (void)resetBonus;
- (void)step:(ccTime)dt;
- (void)jump;
- (void)showHighscores;
@end


@implementation Game

+ (CCScene *)scene
{
    CCScene *game = [CCScene node];
    
    Game *layer = [Game node];
    [game addChild:layer];
    
    return game;
}

- (id)init {
//	NSLog(@"Game::init");
	
	if(![super init]) return nil;
	
	gameSuspended = YES;

	CCSpriteBatchNode *batchNode = (CCSpriteBatchNode *)[self getChildByTag:kSpriteManager];

	[self initPlatforms];
	
	CCSprite *bird = [CCSprite spriteWithTexture:[batchNode texture] rect:CGRectMake(608,16,44,32)];
	[batchNode addChild:bird z:4 tag:kBird];

	CCSprite *bonus;

	for(int i=0; i<kNumBonuses; i++) {
		bonus = [CCSprite spriteWithTexture:[batchNode texture] rect:CGRectMake(608+i*32,256,25,25)];
		[batchNode addChild:bonus z:4 tag:kBonusStartTag+i];
		bonus.visible = NO;
	}

//	LabelAtlas *scoreLabel = [LabelAtlas labelAtlasWithString:@"0" charMapFile:@"charmap.png" itemWidth:24 itemHeight:32 startCharMap:' '];
//	[self addChild:scoreLabel z:5 tag:kScoreLabel];
	
	CCLabelBMFont *scoreLabel = [CCLabelBMFont labelWithString:@"0" fntFile:@"bitmapFont.fnt"];
	[self addChild:scoreLabel z:5 tag:kScoreLabel];
	scoreLabel.position = ccp(160,430);

	[self schedule:@selector(step:)];
	
	self.isTouchEnabled = NO;
	self.isAccelerometerEnabled = YES;

    //加速感应
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kFPS)];
	
	[self startGame];
	
	return self;
}

- (void)dealloc {
//	NSLog(@"Game::dealloc");
	[super dealloc];
}

- (void)initPlatforms {
//	NSLog(@"initPlatforms");
	
	currentPlatformTag = kPlatformsStartTag;
	while(currentPlatformTag < kPlatformsStartTag + kNumPlatforms) {
		[self initPlatform];
		currentPlatformTag++;
	}
	
	[self resetPlatforms];
}

//随机选择台阶图片创建
- (void)initPlatform {

	CGRect rect;
	switch(random()%2) {
		case 0: rect = CGRectMake(608,64,102,36); break;
		case 1: rect = CGRectMake(608,128,90,32); break;
	}

	CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
	CCSprite *platform = [CCSprite spriteWithTexture:[batchNode texture] rect:rect];
	[batchNode addChild:platform z:3 tag:currentPlatformTag];
}

- (void)startGame {
//	NSLog(@"startGame");

	score = 0;
	
	[self resetClouds];
	[self resetPlatforms];
	[self resetBird];
	[self resetBonus];
	
    //停用所有idle timer
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	gameSuspended = NO;
}

- (void)resetPlatforms {
//	NSLog(@"resetPlatforms");
	
	currentPlatformY = -1;
	currentPlatformTag = kPlatformsStartTag;
	currentMaxPlatformStep = 60.0f;
	currentBonusPlatformIndex = 0;
	currentBonusType = 0;
	platformCount = 0;

	while(currentPlatformTag < kPlatformsStartTag + kNumPlatforms) {
		[self resetPlatform];
		currentPlatformTag++;
	}
}

- (void)resetPlatform {
	
    //游戏开始的初始化第一个位置
	if(currentPlatformY < 0) {
		currentPlatformY = 30.0f;
	} else {
        //currentPlatformY 范围 kMinPlatformStep~currentMaxPlatformStep
		currentPlatformY += random() % (int)(currentMaxPlatformStep - kMinPlatformStep) + kMinPlatformStep;
		if(currentMaxPlatformStep < kMaxPlatformStep) {
			currentMaxPlatformStep += 0.5f;
		}
	}
	
	CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
	CCSprite *platform = (CCSprite*)[batchNode getChildByTag:currentPlatformTag];
	
    //判断是否翻转
	if(random()%2==1) platform.scaleX = -1.0f;
	
	float x;
	CGSize size = platform.contentSize;
    //platform的第一个固定位置
	if(currentPlatformY == 30.0f) {
		x = 160.0f;
	} else {
        //x size.width/2 ~320-size.width/2,保证platform全部显示出来
		x = random() % (320-(int)size.width) + size.width/2;
	}
	
	platform.position = ccp(x,currentPlatformY);
	platformCount++;
//	NSLog(@"platformCount = %d",platformCount);
	
    //设置bouns位置
	if(platformCount == currentBonusPlatformIndex) {
//		NSLog(@"platformCount == currentBonusPlatformIndex");
		CCSprite *bonus = (CCSprite*)[batchNode getChildByTag:kBonusStartTag+currentBonusType];
		bonus.position = ccp(x,currentPlatformY+30);
		bonus.visible = YES;
	}
}

- (void)resetBird {
//	NSLog(@"resetBird");

	CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
	CCSprite *bird = (CCSprite*)[batchNode getChildByTag:kBird];
	
	bird_pos.x = 160;
	bird_pos.y = 160;
	bird.position = bird_pos;
	
	bird_vel.x = 0;
	bird_vel.y = 0;
	
	bird_acc.x = 0;
	bird_acc.y = -550.0f; //加速度
	
	birdLookingRight = YES;
	bird.scaleX = 1.0f;
}

- (void)resetBonus {
//	NSLog(@"resetBonus");
	
	CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
	CCSprite *bonus = (CCSprite*)[batchNode getChildByTag:kBonusStartTag+currentBonusType];
	bonus.visible = NO;
	currentBonusPlatformIndex += random() % (kMaxBonusStep - kMinBonusStep) + kMinBonusStep;
	if(score < 10000) {
		currentBonusType = 0;
	} else if(score < 50000) {
		currentBonusType = random() % 2;
	} else if(score < 100000) {
		currentBonusType = random() % 3;
	} else {
		currentBonusType = random() % 2 + 2;
	}
}

- (void)step:(ccTime)dt {
//	NSLog(@"Game::step");

	[super step:dt];
	
	if(gameSuspended) return;

	CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
	CCSprite *bird = (CCSprite*)[batchNode getChildByTag:kBird];
	
	bird_pos.x += bird_vel.x * dt;
	//bird的左右翻转
	if(bird_vel.x < -30.0f && birdLookingRight) {
		birdLookingRight = NO;        
		bird.scaleX = -1.0f;
	} else if (bird_vel.x > 30.0f && !birdLookingRight) {
		birdLookingRight = YES;
		bird.scaleX = 1.0f;
	}

	CGSize bird_size = bird.contentSize;
	float max_x = 320-bird_size.width/2;
	float min_x = 0+bird_size.width/2;
	//阻止bird超过屏幕
	if(bird_pos.x>max_x) bird_pos.x = max_x;
	if(bird_pos.x<min_x) bird_pos.x = min_x;
	//根据加速度和速度改变y坐标
	bird_vel.y += bird_acc.y * dt;
	bird_pos.y += bird_vel.y * dt;
	//检测金币碰撞
	CCSprite *bonus = (CCSprite*)[batchNode getChildByTag:kBonusStartTag+currentBonusType];
	if(bonus.visible) {
		CGPoint bonus_pos = bonus.position;
		float range = 20.0f;
		if(bird_pos.x > bonus_pos.x - range &&
		   bird_pos.x < bonus_pos.x + range &&
		   bird_pos.y > bonus_pos.y - range &&
		   bird_pos.y < bonus_pos.y + range ) {
			switch(currentBonusType) {
				case kBonus5:   score += 5000;   break;
				case kBonus10:  score += 10000;  break;
				case kBonus50:  score += 50000;  break;
				case kBonus100: score += 100000; break;
			}
			NSString *scoreStr = [NSString stringWithFormat:@"%d",score];
			CCLabelBMFont *scoreLabel = (CCLabelBMFont*)[self getChildByTag:kScoreLabel];
			[scoreLabel setString:scoreStr];
            //得到bouns增加分数动画
			id a1 = [CCScaleTo actionWithDuration:0.2f scaleX:1.5f scaleY:0.8f];
			id a2 = [CCScaleTo actionWithDuration:0.2f scaleX:1.0f scaleY:1.0f];
			id a3 = [CCSequence actions:a1,a2,a1,a2,a1,a2,nil];
			[scoreLabel runAction:a3];
			[self resetBonus];
		}
	}
	
	int t;
	//bird 下降时候检测与platform碰撞
	if(bird_vel.y < 0) {
		
		t = kPlatformsStartTag;
		for(t; t < kPlatformsStartTag + kNumPlatforms; t++) {
			CCSprite *platform = (CCSprite*)[batchNode getChildByTag:t];

			CGSize platform_size = platform.contentSize;
			CGPoint platform_pos = platform.position;
			//platform的最左和最右，两端哥扩展10
			max_x = platform_pos.x - platform_size.width/2 - 10;
			min_x = platform_pos.x + platform_size.width/2 + 10;
            //bird 和platfor碰撞时候，bird最低点，即min_y
			float min_y = platform_pos.y + (platform_size.height+bird_size.height)/2 - kPlatformTopPadding;
			//检测碰撞
			if(bird_pos.x > max_x &&
			   bird_pos.x < min_x &&
			   bird_pos.y > platform_pos.y &&
			   bird_pos.y < min_y) {
				[self jump];
			}
		}
		
        //如果掉落出屏幕，则结束游戏，
		if(bird_pos.y < -bird_size.height/2) {
			[self showHighscores];
		}
		
	} else if(bird_pos.y > 240) {
        //控制整体画面的移动
		//需要上移的距离
		float delta = bird_pos.y - 240;
		bird_pos.y = 240;

		currentPlatformY -= delta;
		
		t = kCloudsStartTag;
		for(t; t < kCloudsStartTag + kNumClouds; t++) {
			CCSprite *cloud = (CCSprite*)[batchNode getChildByTag:t];
			CGPoint pos = cloud.position;
            //根据cloud的远近距离(scaleY)来判断cloud相应上移的距离
			pos.y -= delta * cloud.scaleY * 0.8f;
            //如果cloud退出屏幕
			if(pos.y < -cloud.contentSize.height/2) {
				currentCloudTag = t;
				[self resetCloud];
			} else {
				cloud.position = pos;
			}
		}
		//移动platform位置
		t = kPlatformsStartTag;
		for(t; t < kPlatformsStartTag + kNumPlatforms; t++) {
			CCSprite *platform = (CCSprite*)[batchNode getChildByTag:t];
			CGPoint pos = platform.position;
			pos = ccp(pos.x,pos.y-delta);
			if(pos.y < -platform.contentSize.height/2) {
				currentPlatformTag = t;
				[self resetPlatform];
			} else {
				platform.position = pos;
			}
		}
		//移动金币位置
		if(bonus.visible) {
			CGPoint pos = bonus.position;
			pos.y -= delta;
			if(pos.y < -bonus.contentSize.height/2) {
				[self resetBonus];
			} else {
				bonus.position = pos;
			}
		}
		//修改得分
		score += (int)delta;
		NSString *scoreStr = [NSString stringWithFormat:@"%d",score];

		CCLabelBMFont *scoreLabel = (CCLabelBMFont*)[self getChildByTag:kScoreLabel];
		[scoreLabel setString:scoreStr];
	}
	
	bird.position = bird_pos;
}

- (void)jump {
    //x速度加上350等于y速度，真有才
	bird_vel.y = 350.0f + fabsf(bird_vel.x);
}

- (void)showHighscores {
//	NSLog(@"showHighscores");
	gameSuspended = YES;
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	
//	NSLog(@"score = %d",score);
	[[CCDirector sharedDirector] replaceScene:
     [CCTransitionFade transitionWithDuration:1 scene:[Highscores sceneWithScore:score] withColor:ccWHITE]];
}

//- (BOOL)ccTouchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
//	NSLog(@"ccTouchesEnded");
//
////	[self showHighscores];
//
////	AtlasSpriteManager *spriteManager = (AtlasSpriteManager*)[self getChildByTag:kSpriteManager];
////	AtlasSprite *bonus = (AtlasSprite*)[spriteManager getChildByTag:kBonus];
////	bonus.position = ccp(160,30);
////	bonus.visible = !bonus.visible;
//
////	BitmapFontAtlas *scoreLabel = (BitmapFontAtlas*)[self getChildByTag:kScoreLabel];
////	id a1 = [ScaleTo actionWithDuration:0.2f scaleX:1.5f scaleY:0.8f];
////	id a2 = [ScaleTo actionWithDuration:0.2f scaleX:1.0f scaleY:1.0f];
////	id a3 = [Sequence actions:a1,a2,a1,a2,a1,a2,nil];
////	[scoreLabel runAction:a3];
//
//	AtlasSpriteManager *spriteManager = (AtlasSpriteManager*)[self getChildByTag:kSpriteManager];
//	AtlasSprite *platform = (AtlasSprite*)[spriteManager getChildByTag:kPlatformsStartTag+5];
//	id a1 = [MoveBy actionWithDuration:2 position:ccp(100,0)];
//	id a2 = [MoveBy actionWithDuration:2 position:ccp(-200,0)];
//	id a3 = [Sequence actions:a1,a2,a1,nil];
//	id a4 = [RepeatForever actionWithAction:a3];
//	[platform runAction:a4];
//	
//	return kEventHandled;
//}

//UIAccelerometer 代理
//UIAcceleration x正负判断左右倾斜，y正负，判断前后倾斜
- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration {
	if(gameSuspended) return;
	float accel_filter = 0.1f;
    NSLog(@"acceleration ---x:%f,y:%f,z:%f",acceleration.x,acceleration.y,acceleration.z);
	bird_vel.x = bird_vel.x * accel_filter + acceleration.x * (1.0f - accel_filter) * 500.0f;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
//	NSLog(@"alertView:clickedButtonAtIndex: %i",buttonIndex);

	if(buttonIndex == 0) {
		[self startGame];
	} else {
		[self startGame];
	}
}

@end
