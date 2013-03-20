#import "GameLayer.h"
#import "BirdSprite.h"
#import "BonusSprite.h"
#import "WinLayer.h"
#import "LoseLayer.h"
#import "MenuLayer.h"
//#define BIRD_ORIGINAL_POSITION ccp(screenWidth/2, IS_IPAD()?96:48)

#define BIRD_ORIGINAL_POSITION_X screenWidth/2
#define BIRD_ORIGINAL_POSITION_Y IS_IPAD()?96:48

enum{
    tMIN=100,
    tPause,
    tAudio,
    tAudioItem,
    tMusic,
    tMusicItem,
    tResume,
    tRestart,
    tPauseLayer,
};

typedef enum{
    eTouchNo,
    eTouchLeft,
    eTouchRight,
}TouchInfo;

@implementation GameLayer{
@private BOOL isTouching;
@private int touchInfos[2]; //0，1为第1，2触摸，有序
    //up指地图上移，mapY下移,扫描先向上，后复原向下，scanMapUp先为yes，后为no
    
@private BOOL scanMapUp;
@private BOOL isTrickCoinShowing;
@private CGPoint trickPosition;
    
    //1000分加一人，单个关卡增加，不影响其余关卡
@private int scoreForLife;
}

@synthesize isTrickWorking;
@synthesize mapX;
@synthesize mapY;
@synthesize screenWidth;
@synthesize screenHeight;
@synthesize tileSize;
@synthesize gameWorld;
@synthesize gameSuspended;
@synthesize score;
@synthesize life;
@synthesize pauseLayer;


- (id)init {
	NSLog(@"Game::---init");
	if(![super init])
        return nil;
    
    //    int tis[2]={0,0};
    //    touchInfos=tis;
    //    touchInfos={0,0};
    memset(touchInfos, 0, sizeof(touchInfos));
    isTouching=NO;
    
    if (IS_IPHONE_5) {
        [self setBgWithFileName:@"bg-568h@2x.jpg"];
    }else{
        [self setBgWithFileName:SD_OR_HD(@"bg.jpg")];
    }
    
    //----------非常重要的初始化工作
    //显示地图  Load birdjump map
    NSUserDefaults* def=[NSUserDefaults standardUserDefaults];
    int level= [def integerForKey:UDF_LEVEL_SELECTED];
    NSString* m=[NSString stringWithFormat:@"birdjump%d.tmx",level];
    NSString* mm = IS_IPAD()?[m stringByReplacingOccurrencesOfString:@".tmx" withString:@"-ipad.tmx"]:m;
    NSLog(@"SD_HD_TMX(m)------%@,mm:%@",SD_HD_TMX(m),mm);
    gameWorld = [CCTMXTiledMap tiledMapWithTMXFile:SD_HD_TMX(m)];
    //init SpriteSheet
    [self initSpriteSheet];
    [self addChild:gameWorld z:zGameWorldMap tag:tGameWorldMap];
    /*
     //遍历所有tile，如果是金币，则增加动画
     // TODO 这里有内存泄露和图片素材的问题，以后做
     NSLog(@"--- gameword tile size is %f * %f",gameWorld.mapSize.width,gameWorld.mapSize.height);
     
     //    for (int i=0; i<gameWorld.mapSize.width/2 ; i++) {
     //        for (int j=0; j<gameWorld.mapSize.height/2; j++) {
     for (int i=gameWorld.mapSize.width/4 ;i>0; i--) {
     for (int j=gameWorld.mapSize.height/4;j>0 ;j--) {
     NSLog(@"i*j= %d",i*j);
     CCTMXLayer* ly=[gameWorld layerNamed:kMAP_LAYER_BONUS];
     CCSprite* tileSprite= [ly tileAt:CGPointMake(i, j)];
     int tileGid= [ly tileGIDAt:CGPointMake(i, j)];
     if (tileGid!=0) {
     CCAction* action= [BonusSprite getActionByBonusType:tileGid];
     [tileSprite runAction:action];
     }
     
     }
     }
     //*/
    
    
    // init param
    CGSize size = [[CCDirector sharedDirector] winSize];
    screenWidth = size.width;
    screenHeight = size.height;
    tileSize = gameWorld.tileSize.width;
    mapX = 0;
    mapY = 0;
    
    
    [BirdSprite BirdWithinLayer:self];
    
    //分数&life
    [self resetGameInfo];
    int currentLevel= [[NSUserDefaults standardUserDefaults] integerForKey:UDF_LEVEL_SELECTED];
    int l=kLIFE_INIT+currentLevel/kLIFE_LEVEL_SCALE;
	CCLabelBMFont *scoreLabel = [CCLabelBMFont labelWithString:[NSString stringWithFormat:kGAME_SCORE_MODEL,0,l] fntFile:@"futura-48.fnt"];
	[self addChild:scoreLabel z:zScoreLablel tag:tScoreLabel];
	scoreLabel.position = ccp(screenWidth/2-20,screenHeight-(IS_IPAD()?100:40));
    scoreLabel.scale=HD2SD_SCALE;
    
    int totalScore= [[NSUserDefaults standardUserDefaults] integerForKey:UDF_TOTAL_SCORE];
    CCLabelBMFont *totalScoreLabel = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"TOTAL SCORE IS %d",totalScore] fntFile:@"futura-48.fnt"];
	[self addChild:totalScoreLabel z:zScoreLablel tag:tScoreLabel];
	totalScoreLabel.position = ccp(screenWidth/2-20,screenHeight-(IS_IPAD()?200:80));
    totalScoreLabel.scale=HD2SD_SCALE;
    
    CCSprite* pn= [CCSprite spriteWithSpriteFrameName:@"button_pause.png"];
    CCSprite* ps= [CCSprite spriteWithSpriteFrameName:@"button_pause.png"];
    CCMenuItemSprite* p=[CCMenuItemSprite itemFromNormalSprite:pn selectedSprite:ps target:self selector:@selector(pauseGame)];
    CCMenu* pauseButton= [CCMenu menuWithItems:p, nil];
    
    pauseButton.position=ccp(winSize.width-(IS_IPAD()?100:50), winSize.height -(IS_IPAD()?100:50));
    pauseButton.visible=NO;
    [self addChild:pauseButton z:zBelowOperation tag:tPause];
    
    //暂停layer
    pauseLayer =[CCLayerColor layerWithColor:ccc4(166,166,166,122) ];
    [self addChild:pauseLayer z:zPauseLayer tag:tPauseLayer];
    pauseLayer.visible=NO;
    
    //audio & music
    BOOL isAudioOn= [[NSUserDefaults standardUserDefaults] boolForKey:UDF_AUDIO];
    CCSprite* audion,*audios;
    if (isAudioOn) {
        audion= [CCSprite spriteWithSpriteFrameName:@"button_audio.png"];
        audios= [CCSprite spriteWithSpriteFrameName:@"button_audio.png"];
    }else{
        audion= [CCSprite spriteWithSpriteFrameName:@"button_audio_bar.png"];
        audios= [CCSprite spriteWithSpriteFrameName:@"button_audio_bar.png"];
    }
    audios.color=ccYELLOW;
    CCMenuItemSprite* audiosa=[CCMenuItemSprite itemFromNormalSprite:audion selectedSprite:audios target:self selector:@selector(audio:)];
    audiosa.tag=tAudioItem;
    CCMenu* audioButton= [CCMenu menuWithItems:audiosa, nil];
    audioButton.position=ccp(winSize.width /2-(IS_IPAD()?100:60), winSize.height*1/3+30);
    [pauseLayer addChild:audioButton z:zAboveOperation tag:tAudio];
    
    BOOL isMusicOn= [[NSUserDefaults standardUserDefaults] boolForKey:UDF_MUSIC];
    CCSprite* musicn,*musics;
    if (isMusicOn) {
        musicn= [CCSprite spriteWithSpriteFrameName:@"button_music.png"];
        musics= [CCSprite spriteWithSpriteFrameName:@"button_music.png"];
    }else{
        musicn= [CCSprite spriteWithSpriteFrameName:@"button_music_bar.png"];
        musics= [CCSprite spriteWithSpriteFrameName:@"button_music_bar.png"];
    }
    musics.color=ccYELLOW;
    CCMenuItemSprite* musicsa=[CCMenuItemSprite itemFromNormalSprite:musicn selectedSprite:musics target:self selector:@selector(music:)];
    musicsa.tag=tMusicItem;
    CCMenu* musicButton= [CCMenu menuWithItems:musicsa, nil];
    musicButton.position=ccp(winSize.width /2+(IS_IPAD()?100:60), winSize.height*1/3+30);
    [pauseLayer addChild:musicButton z:zAboveOperation tag:tMusic];
    
    
    //menu & refresh & start
    CCSprite* mn= [CCSprite spriteWithSpriteFrameName:@"button_menu.png"];
    CCSprite* ms= [CCSprite spriteWithSpriteFrameName:@"button_menu.png"];
    ms.color=ccYELLOW;
    CCMenuItemSprite* msa=[CCMenuItemSprite itemFromNormalSprite:mn selectedSprite:ms target:self selector:@selector(menu)];
    CCMenu* menuButton= [CCMenu menuWithItems:msa, nil];
    menuButton.position=ccp(winSize.width /2-(IS_IPAD()?200:100), winSize.height*1/3-100);
    [pauseLayer addChild:menuButton z:zAboveOperation];
    
    
    
    CCSprite* rsn= [CCSprite spriteWithSpriteFrameName:@"button_refresh.png"];
    CCSprite* rss= [CCSprite spriteWithSpriteFrameName:@"button_refresh.png"];
    rss.color=ccYELLOW;
    CCMenuItemSprite* rsa=[CCMenuItemSprite itemFromNormalSprite:rsn selectedSprite:rss target:self selector:@selector(restartGame)];
    CCMenu* restartButton= [CCMenu menuWithItems:rsa, nil];
    restartButton.position=ccp(winSize.width /2, winSize.height*1/3-100);
    [pauseLayer addChild:restartButton z:zAboveOperation];
    
    
    
    CCSprite* rn= [CCSprite spriteWithSpriteFrameName:@"button_start.png"];
    CCSprite* rs= [CCSprite spriteWithSpriteFrameName:@"button_start.png"];
    rs.color=ccYELLOW;
    CCMenuItemSprite* r=[CCMenuItemSprite itemFromNormalSprite:rn selectedSprite:rs target:self selector:@selector(resumeGame)];
    CCMenu* resumeButton= [CCMenu menuWithItems:r, nil];
    resumeButton.position=ccp(winSize.width/2+(IS_IPAD()?200:100), winSize.height*1/3-100);
    [pauseLayer addChild:resumeButton z:zAboveOperation];
    
    
    
    /*
     //测试BonusSprite动画是否可以工作
     BonusSprite* coins= [BonusSprite BonusWithinLayer:self bType:tCoinGold bTag:zScoreLablel];
     coins.position=ccp(50, 50);
     [coins runAction:[BonusSprite getActionByBonusType:tCoinGold]];
     //*/
    /*
     //测试BonusSprite动画是否可以工作
     BonusSprite* coins= [BonusSprite BonusWithinLayer:self bType:tCoinGold bTag:zScoreLablel];
     coins.position=ccp(50, 50);
     [coins runAction:[BonusSprite getActionByBonusType:tCoinGold]];
     //*/
    
	
	self.isAccelerometerEnabled = YES;
    
    //加速感应
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kFPS)];
    
    
    //TODO 游戏开始需要给用户准备时间
//    scanMapUp=YES;
//    [self performSelector:@selector(startSchedueScanMap) withObject:nil afterDelay:1];
    
    [self performSelector:@selector(startGame) withObject:nil afterDelay:kGAME_AFTER_DELAY];
    [self getChildByTag:tPause].visible=YES;
    
    self.isTouchEnabled=YES;
    
	return self;
}


-(void)initSpriteSheet{
    //init---- character.png
    [BirdSprite initSpriteSheet:self.gameWorld];
    //    [BonusSprite initSpriteSheet:self];
    //HERE 这里将map的texture加入到spritesheet中，是为了在tile动画做准备
    [BonusSprite initSpriteSheet:self.gameWorld texture:[gameWorld layerNamed:kMAP_LAYER_BONUS ].texture];
    
    //初始化按钮sheet
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:SD_HD_PLIST(@"button_sheet.plist")];
    CCSpriteBatchNode *buttonSpriteSheet = [CCSpriteBatchNode
                                            batchNodeWithFile:@"button_sheet.png"];
    //这里tCharacterManager的z要在tSpriteManager之上，这样此才不会被覆盖
    [self addChild:buttonSpriteSheet z:zButtonSpriteSheet tag:tButtonManager];
}

- (void)dealloc {
	[super dealloc];
}
#pragma mark game control
-(void)startSchedueScanMap{
    [self schedule:@selector(scanMap:)];
}
- (void)scanMap :(ccTime)dt{
    
    //step可以固定scan时间，也可以固定速度，两选一，觉得都行，元芳，你怎么看
    // 还是按步长来吧，因为地图可能会很长，速度就不均匀了
    //    float step=([self gameWorldHeight]*2.0f)/(kGAME_MAP_SCAN_TIME*kFPS);
    float step=kGAME_MAP_SCAN_STEP;
//    NSLog(@"scanMap---scanMapUp:%d，step:%f",scanMapUp,step);
    if (scanMapUp) {
        if (abs(mapY)+winSize.height<[self gameWorldHeight]) {
            //继续上移
            mapY-=step;
        } else {
            //map到顶端，开始下移复原
            scanMapUp=NO;
        }
    } else {
        if (abs(mapY)>0) {
            //继续下移
            mapY+=step;
        } else {
            //map到底部，停止移动，开始游戏
            [self unschedule:@selector(scanMap:)];
            [self performSelector:@selector(startGame) withObject:nil afterDelay:kGAME_AFTER_DELAY];
            [self getChildByTag:tPause].visible=YES;
        }
    }
    //防止步长过大而越界
    if (mapY<(-[self gameWorldHeight])) {
        mapY=(-[self gameWorldHeight]);
    } else if(mapY>0){
        mapY=0;
    }
    gameWorld.position = ccp(mapX, mapY);
    
}
- (void)startGame {
    [self schedule:@selector(step:)];
    //停用所有idle timer
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}



- (void)resetBird {
	CCSpriteBatchNode *charaBatchNode = (CCSpriteBatchNode *)[gameWorld getChildByTag:tCharacterManager];
	BirdSprite *bird = (BirdSprite*)[charaBatchNode getChildByTag:tBird];
	bird.position = ccp(BIRD_ORIGINAL_POSITION_X, BIRD_ORIGINAL_POSITION_Y);
    bird.vel=ccVertexMake(0, kVEL_INIT);
    bird.acc=ccVertexMake(0, kACC);
}
- (void)resetGameInfo {
    isTrickWorking=NO;
    isTrickCoinShowing=NO;
    trickPosition=ccp(0,0);
    mapX=0;
    mapY=0;
    gameWorld.position = ccp(mapX, mapY);
    int currentLevel= [[NSUserDefaults standardUserDefaults] integerForKey:UDF_LEVEL_SELECTED];
    life=kLIFE_INIT+currentLevel/kLIFE_LEVEL_SCALE;
    gameSuspended = NO;
	score = 0;
    scoreForLife=0;
    [self resetBird];
}
-(void)pauseGame{
    if ([SysConfig needAudio]){
        [[SimpleAudioEngine sharedEngine] playEffect:@"button_select.mp3"];
    }
    gameSuspended=YES;
    [self unschedule:@selector(step:)];
    [self showPauseLayer:YES];
    
}
-(void)audio:(id)sender{
    NSLog(@"send:%@",sender);
    CCMenuItemSprite* i=(CCMenuItemSprite*)sender;
    NSUserDefaults* def= [NSUserDefaults standardUserDefaults];
    BOOL isAudioOn= ![def boolForKey:UDF_AUDIO];
    [def setBool:isAudioOn forKey:UDF_AUDIO];
    [SysConfig setNeedAudio:isAudioOn];
    CCSprite* audion,*audios;
    if (isAudioOn) {
        audion= [CCSprite spriteWithSpriteFrameName:@"button_audio.png"];
        audios= [CCSprite spriteWithSpriteFrameName:@"button_audio.png"];
    }else{
        audion= [CCSprite spriteWithSpriteFrameName:@"button_audio_bar.png"];
        audios= [CCSprite spriteWithSpriteFrameName:@"button_audio_bar.png"];
    }
    audios.color=ccYELLOW;
    i.normalImage = audion;
    i.selectedImage=audios;
    
}
-(void)music:(id)sender{
    NSLog(@"send:%@",sender);
    CCMenuItemSprite* i=(CCMenuItemSprite*)sender;
    NSUserDefaults* def= [NSUserDefaults standardUserDefaults];
    BOOL isMusicOn= ![def boolForKey:UDF_MUSIC];
    [def setBool:isMusicOn forKey:UDF_MUSIC];
    [SysConfig setNeedMusic:isMusicOn];
    if (isMusicOn) {
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"gamebg.mp3" loop:YES];
    } else {
        [[SimpleAudioEngine sharedEngine] stopBackgroundMusic];
    }
    
    CCSprite* musicn,*musics;
    if (isMusicOn) {
        musicn= [CCSprite spriteWithSpriteFrameName:@"button_music.png"];
        musics= [CCSprite spriteWithSpriteFrameName:@"button_music.png"];
    }else{
        musicn= [CCSprite spriteWithSpriteFrameName:@"button_music_bar.png"];
        musics= [CCSprite spriteWithSpriteFrameName:@"button_music_bar.png"];
    }
    musics.color=ccYELLOW;
    i.normalImage = musicn;
    i.selectedImage=musics;
    
}
-(void)resumeGame{
    if ([SysConfig needAudio]){
        [[SimpleAudioEngine sharedEngine] playEffect:@"button_select.mp3"];
    }
    gameSuspended=NO;
    isTouching=NO;
    memset(touchInfos, 0, sizeof(touchInfos));
    [self schedule:@selector(step:)];
    [self showPauseLayer:NO];
}
-(void)restartGame{
    [self resetGameInfo];
    [self performSelector:@selector(startGame) withObject:nil afterDelay:kGAME_AFTER_DELAY];
    [self showPauseLayer:NO];
}
-(void) menu
{
	CCScene *sc = [CCScene node];
	[sc addChild:[MenuLayer node]];
	[[CCDirector sharedDirector] replaceScene:  [CCTransitionSplitRows transitionWithDuration:1.0f scene:sc]];
}
-(void)showPauseLayer:(BOOL)show{
    CCLayer* pl=(CCLayer*)[self getChildByTag:tPauseLayer];
    pl.visible=show;
    pl.isTouchEnabled=!show;
}


#pragma  mark -
- (void)step:(ccTime)dt {
    //	NSLog(@"----------Game::step");
	if(gameSuspended) return;
    //1000分加一人，单个关卡增加，不影响其余关卡
    if(score/kLIFE_SCORE_SCALE>scoreForLife){
        scoreForLife=score/kLIFE_SCORE_SCALE;
        life++;
    }
    
    
    CCSpriteBatchNode *charaBatchNode = (CCSpriteBatchNode *)[gameWorld getChildByTag:tCharacterManager];
	BirdSprite *bird = (BirdSprite*)[charaBatchNode getChildByTag:tBird];
    
	CGSize bird_size = bird.contentSize;
	float max_x = [self gameWorldWidth] -bird_size.width/2;
	float min_x = 0+bird_size.width/2;
	//阻止bird超过屏幕
	if(bird.position.x>max_x) bird.position = ccp(max_x,bird.position.y);
	if(bird.position.x<min_x) bird.position =ccp( min_x,bird.position.y);
    //根据加速度和速度改变y坐标
    bird.vel =ccVertexMake(bird.vel.x, bird.acc.y * dt+bird.vel.y);
    
    //bird的position，速度改变，
    [bird changePositon:self xStep:bird.vel.x*dt yStep:bird.vel.y*dt];
    //移动地图，检测碰撞
    [self setWorldPosition];
    
    //判断是否跌出屏幕决定是否结束游戏
    if (bird.position.y - mapY < bird.textureRect.size.height ){
        //FIXME 调试方便，暂时不让role死亡
        //[self showHighscores];
        NSLog(@"bird is bollow the bottom map !!!!!!!!!!!!!!");
        bird.vel=ccVertexMake(0, kVEL_INIT);
        bird.position=ccp(bird.position.x, BIRD_ORIGINAL_POSITION_Y);
    }else if (bird.position.y+bird.textureRect.size.height > [self gameWorldHeight] ){
        NSLog(@"bird is above the top map !!!!!!!!!!!!!!");
        bird.vel=ccVertexMake(0, -kVEL_INIT);
        bird.position=ccp(bird.position.x, -BIRD_ORIGINAL_POSITION_Y);
    }
    //update ui
    CCLabelBMFont *scoreLabel=(CCLabelBMFont*)[self getChildByTag:tScoreLabel];
    [scoreLabel setString:[NSString stringWithFormat:kGAME_SCORE_MODEL,score,life]];
    if (life<=0 ) {
        [self gameOverWin:NO];
    }
    if (isTrickWorking) {
        bird.trick_particles.position=bird.position;
    }
    
    if (isTouching) {
        //        NSLog(@"---isTouching");
        [self changeVel:dt];
    }
    
    //显示trick bunos
    //*
    long currentTime= (long)[[NSDate date] timeIntervalSince1970];
    int tenS= (((currentTime/10)%10)%2); //十位数秒值
    //    int tenS= (currentTime%2); //十位数秒值
    if (tenS==0) { //偶数显示
        if (!isTrickCoinShowing) {
            //在随机位置放置tric tile
            //定义随机数种子
            RANDOM_SEED();
            int mRate=rand()%(2*60*10);//60,因为step在schedule，10秒为单位
            //显示频率太大了，变为原来的1/4,
            NSLog(@"----mRate:%d",mRate);
            if (mRate!=0) {
                return;
            }
            
            int tx=rand()%((int)(winSize.width))+abs(mapX);
            int ty=rand()%((int)(winSize.height))+abs(mapY);
            CCTMXLayer* ly=[gameWorld layerNamed:kMAP_LAYER_BONUS];
            CGPoint tp= [self tileCoordinateFromPos:ccp(tx, ty)];
            CCSprite* trickCoin= [ly tileAt: tp];
            int tileGid= [ly tileGIDAt:tp];
            NSLog(@"trick coin's gid is %d",tileGid);
            if (tileGid!=tAwardFlag && tileGid!=tBlockNormal) {//如果不是红旗，则换成trick
                CCSpriteFrame* frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"coin_trick01_0000.png"];
                [trickCoin setDisplayFrame:frame];
                [ly setTileGID:tCoinTrick at:tp];
                CCAction* action= [BonusSprite getActionByBonusType:tCoinTrick];
                [trickCoin runAction:action];
                trickPosition=tp;
                CCSprite* trickParticle= [BonusSprite BonusWithinLayer:self.gameWorld bType:tCoinTrickParticle bTag:tCoinTrickParticle];
                trickParticle.position=ccp(tx,ty);
                NSLog(@"show trick coin at (map):%d,%d  (tile):%f,%f",tx,ty,trickPosition.x,trickPosition.y);
                isTrickCoinShowing=YES;
            }
        }
    } else if(tenS==1) { //奇数隐藏
        if (isTrickCoinShowing) {
            CCTMXLayer* ly=[gameWorld layerNamed:kMAP_LAYER_BONUS];
            [ly setTileGID:0 at:trickPosition];
            CCSpriteBatchNode *bonusSheet = (CCSpriteBatchNode*)[gameWorld getChildByTag:tBonusManager];
            [bonusSheet removeChildByTag:tCoinTrickParticle cleanup:YES];
            NSLog(@"dismiss trick coin at %f,%f",trickPosition.x,trickPosition.y);
            trickPosition=ccp(0, 0);
            isTrickCoinShowing=NO;
        }
    }
    //*/
}
-(BOOL)checkIsLeft{
    BOOL isLeft=NO;
    switch (touchInfos[1]) {
        case eTouchNo:
            switch (touchInfos[0]) {
                case eTouchNo:
                    isTouching=NO;
                    return NO;
                    break;
                case eTouchLeft:
                    isLeft=YES;
                    break;
                case eTouchRight:
                    isLeft=NO;
                    break;
            }
            break;
        case eTouchLeft:
            isLeft=YES;
            break;
        case eTouchRight:
            isLeft=NO;
            break;
    }
    return isLeft;
    
}
-(void)changeVel:(ccTime)dt{
    CCSpriteBatchNode *charaBatchNode = (CCSpriteBatchNode *)[gameWorld getChildByTag:tCharacterManager];
    BirdSprite *bird = (BirdSprite*)[charaBatchNode getChildByTag:tBird];
    //*
    BOOL isLeft= [self checkIsLeft];
    if (!isTouching) {
        return;
    }
    float acc=IS_IPAD()?(isLeft?-0.3:0.3):(isLeft?-0.27:0.27);
    float vx= bird.vel.x * 0.1f + acc * (1.0f - 0.1f) * 1000.0f;
    //     NSLog(@"bird old vel:%f,new:%f",bird.vel.x,vx);
    /*/
     //想用加速度方法，但是没法急转弯，感觉role很不灵活
     int a=768;
     float acc=isLeft?-1*a:a;
     float vx= bird.vel.x +acc*dt;
     NSLog(@"bird old vel:%f,new:%f",bird.vel.x,vx);
     //*/
    bird.vel = ccVertexMake(vx,bird.vel.y);
    
}

#pragma mark view forward

- (void)gameOverWin:(BOOL)win {
    NSUserDefaults* def= [NSUserDefaults standardUserDefaults];
    int s=[def integerForKey:UDF_TOTAL_SCORE];
    [def setInteger:self.score+s forKey:UDF_TOTAL_SCORE ];
    
    NSLog(@"gameOverWin---self:%@",self);
	gameSuspended = YES;
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    if (win) {
        CCScene* sc=[CCScene node];
        WinLayer* la=[WinLayer node];
        la.score=self.score;
        [sc addChild:la];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1 scene:sc withColor:ccWHITE]];
    } else {
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:1 scene:[LoseLayer scene] withColor:ccWHITE]];
    }
	
    
    //清空本地所有的素材
    [self unschedule:@selector(step:)];
    //FIXME removeAllChildrenWithCleanup will cause bad access ,but i need to realease them
    //    [self removeAllChildrenWithCleanup:YES];
}



#pragma mark -------- map start
-(unsigned int)tileIDFromPosition:(CGPoint)pos withLayer:(NSString*) layerName
{
	CGPoint cpt = [self tileCoordinateFromPos:pos];
	CCTMXLayer *ly = [gameWorld layerNamed:layerName];
	
	if (cpt.x < 0)
		return -1;
	
	if (cpt.y < 0)
		return -1;
	
	if (cpt.x >= ly.layerSize.width)
		return -1;
	
	if (cpt.y >= ly.layerSize.height)
		return -1;
    //	NSLog(@"tile gid 14*588:%d,",[ly tileGIDAt:ccp(14, 588)]);
    //    NSLog(@"tile gid 13*589:%d,",[ly tileGIDAt:ccp(13, 589)]);
    //    NSLog(@"tile gid 13*589:%d,",[ly tileGIDAt:ccp(13, 589)]);
    //    NSLog(@"tile gid 13*592:%d,",[ly tileGIDAt:ccp(13, 592)]);
    //    NSLog(@"tile gid 13*593:%d,",[ly tileGIDAt:ccp(13, 593)]);
    //    NSLog(@"tile gid 14*593:%d,",[ly tileGIDAt:ccp(14, 593)]);
    //    NSLog(@"tile gid 14*592:%d,",[ly tileGIDAt:ccp(14, 592)]);
    //    NSLog(@"tild gid of %f,%f is %d",cpt.x,cpt.y,[ly tileGIDAt:cpt]);
	return [ly tileGIDAt:cpt];
}

-(CGPoint)tileCoordinateFromPos:(CGPoint)pos
{
	int cox, coy;
    
	CCTMXLayer *ly = [gameWorld layerNamed:kMAP_LAYER_BONUS];
	
	if (ly == nil)
	{
		NSLog(@"ERROR: Layer not found!");
		return ccp(-1, -1);
	}
	
	CGSize szLayer = [ly layerSize];
	CGSize szTile = [gameWorld tileSize];
	
	cox = pos.x / szTile.width;
	coy = szLayer.height - pos.y / szTile.height;
	
	if ((cox >= 0) && (cox < szLayer.width) && (coy >= 0) && (coy < szLayer.height))
	{
		return ccp(cox, coy);
	}
	else {
		return ccp(-1, -1);
	}
	
}


-(float) gameWorldWidth
{
	return gameWorld.mapSize.width * tileSize;
}
-(float) gameWorldHeight
{
	return gameWorld.mapSize.height * tileSize;
}


//移动地图
- (void) setWorldPosition
{
    CCSpriteBatchNode *charaBatchNode = (CCSpriteBatchNode *)[gameWorld getChildByTag:tCharacterManager];
	BirdSprite *bird = (BirdSprite*)[charaBatchNode getChildByTag:tBird];
	
	CGRect rc = [bird textureRect];
    
	// Check if the dozer is near the edge of the map
	if(bird.position.x < screenWidth/2 - rc.size.width / 2)
		mapX = 0;
	else if(bird.position.x > [self gameWorldWidth] - (screenWidth / 2))
		mapX = -[self gameWorldWidth];
    //        mapX = 0;
	else
        //map随role的移动而移动
		mapX = -(bird.position.x - (screenWidth/2) + rc.size.width / 2);
	
	if(bird.position.y < screenHeight/2 - rc.size.height / 2)
		mapY = 0;
	else if(bird.position.y > [self gameWorldHeight] - (screenHeight/2))
    {
        mapY = -[self gameWorldHeight];
    }
	else
		mapY = -(bird.position.y - (screenHeight/2) + rc.size.height / 2);
	
	// Reset the map if the next position is past the edge
	if(mapX > 0) mapX = 0;
	if(mapY > 0) mapY = 0;
	
	if(mapX < -([self gameWorldWidth] - screenWidth))
        mapX = -([self gameWorldWidth] - screenWidth);
	if(mapY < -([self gameWorldHeight] - screenHeight))
        mapY = -([self gameWorldHeight] - screenHeight);
	
	// [gameWorld setPosition:ccp(mapX, mapY)];
	gameWorld.position = ccp(mapX, mapY);
	
}


#pragma mark 重力判断
//UIAccelerometer 代理
//UIAcceleration x正负判断左右倾斜，y正负，判断前后倾斜
- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration {
	if(!gameSuspended && [SysConfig operation]!=oGesture) {
        float accel_filter = 0.1f;
        //    NSLog(@"acceleration ---x:%f,y:%f,z:%f",acceleration.x,acceleration.y,acceleration.z);
        CCSpriteBatchNode *charaBatchNode = (CCSpriteBatchNode *)[gameWorld getChildByTag:tCharacterManager];
        BirdSprite *bird = (BirdSprite*)[charaBatchNode getChildByTag:tBird];
        //    float vx= bird.vel.x+bird.vel.x * accel_filter + acceleration.x * (1.0f - accel_filter) * 500.0f;
        //    float vy= bird.vel.y+bird.vel.y * accel_filter + acceleration.y * (1.0f - accel_filter) * 500.0f;
        
        if (cUSE_Y_ACC) {
            float vx= bird.vel.x+(bird.vel.x * accel_filter + acceleration.x * (1.0f - accel_filter) * 500.0f)/KACC_SCALE;
            float vy= bird.vel.y+(bird.vel.y * accel_filter + acceleration.y * (1.0f - accel_filter) * 500.0f)/KACC_SCALE;
            bird.vel = ccVertexMake(abs(vx)<kVEL_MAX?vx:(vx*kVEL_MAX)/abs(vx),abs(vy)<kVEL_MAX?vy:(vy*kVEL_MAX)/abs(vy));
        } else {
            float vx= bird.vel.x * accel_filter + acceleration.x * (1.0f - accel_filter) * 500.0f;
            bird.vel = ccVertexMake(vx,bird.vel.y);
        }
    }
    
}
#pragma mark gesture
-(void) registerWithTouchDispatcher
{
    //swallowsTouches决定是否传递touches事件给touch chain
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:INT_MIN+1 swallowsTouches:NO];
}
//return NO会取消后继的touch事件
-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    if(!gameSuspended && [SysConfig operation]!=oAcceleration) {
        isTouching=YES;
        
        CGPoint tp = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        BOOL isLeft=(tp.x<winsize.width/2);
        //先处理0，后处理1，如果多出了，为第三触摸，不处理
        if (touchInfos[0]==eTouchNo) {
            touchInfos[0]=isLeft?eTouchLeft:eTouchRight;
        } else if(touchInfos[1]==eTouchNo){
            touchInfos[1]=isLeft?eTouchLeft:eTouchRight;
        }
        
        NSLog(@"ccTouchBegan --isLeft:%d,touchInfos[0]:%d,touchInfos[1]:%d",isLeft,touchInfos[0],touchInfos[1]);
        return YES;
    }else{
        return NO;
    }
    
    
    
    
}
-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event{
    if(!gameSuspended && [SysConfig operation]!=oAcceleration) {
        CGPoint tp = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        BOOL isLeft=(tp.x<winsize.width/2);
        //先处理0，后处理1，如果多出了，为第三触摸，不处理
        //这里假设全触摸，一左一右，没有手指跨屏幕滑动,判断触摸左右来取消左右触摸
        if (touchInfos[1]==(isLeft?eTouchLeft:eTouchRight)) {
            touchInfos[1]=eTouchNo;
        } else if(touchInfos[0]==(isLeft?eTouchLeft:eTouchRight)){
            //交换0，1，保证0为剩余的一指的触摸点
            touchInfos[0]=touchInfos[1];
            touchInfos[1]=eTouchNo;
        }else{
            isTouching=NO;
        }
        
        NSLog(@"ccTouchCancelled --isLeft:%d,touchInfos[0]:%d,touchInfos[1]:%d",isLeft,touchInfos[0],touchInfos[1]);
    }
}
//-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
//    if(!gameSuspended && [SysConfig operation]!=oAcceleration) {
////        NSLog(@"ccTouchMoved --");
//        //    CGPoint touchStop = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
//    }
//}

#pragma mark CCStandardTouchDelegate
-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
    if(!gameSuspended && [SysConfig operation]!=oAcceleration) {
        CGPoint tp = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        BOOL isLeft=(tp.x<winsize.width/2);
        //先处理0，后处理1，如果多出了，为第三触摸，不处理
        //这里假设全触摸，一左一右，没有手指跨屏幕滑动,判断触摸左右来取消左右触摸
        
        
        if (touchInfos[1]==(isLeft?eTouchLeft:eTouchRight)) {
            touchInfos[1]=eTouchNo;
        } else if(touchInfos[0]==(isLeft?eTouchLeft:eTouchRight)){
            //交换0，1，保证0为剩余的一指的触摸点
            touchInfos[0]=touchInfos[1];
            touchInfos[1]=eTouchNo;
        }else{
            isTouching=NO;
        }
        
        NSLog(@"ccTouchEnded --isLeft:%d,touchInfos[0]:%d,touchInfos[1]:%d",isLeft,touchInfos[0],touchInfos[1]);
        
    }
    
    
}



@end
