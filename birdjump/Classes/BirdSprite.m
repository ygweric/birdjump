//
//  BirdSprite.m
//  birdjump
//
//  Created by Eric on 12-11-4.
//  Copyright (c) 2012年 Symetrix. All rights reserved.
//

#import "BirdSprite.h"
#import "BonusSprite.h"
#import "CustomParticleHeader.h"
typedef struct{
    //bonus碰撞检测
    BOOL touched;
    //touchBlockGid 记录碰撞的tile gid,如果碰撞多个block，选择扣分最多的
    unsigned int tid;
    //记录碰撞tile位置，为以后展示动画作准备
    CGPoint position;
}TouchInfo;


@implementation BirdSprite{
    
}
@synthesize vel;
@synthesize acc;

//设置n种粒子，分别渲染不同奖励变化
@synthesize trick_particles;
@synthesize currentGrade;

@synthesize normalAction;
@synthesize upAction;
@synthesize downAction;
@synthesize layer=layer_;

#pragma mark -

+ (id) BirdWithinLayer:(CCLayer *)layer
{
    
    GameLayer* gLayer=(GameLayer*)layer;
    CCSpriteBatchNode *spriteSheet = (CCSpriteBatchNode*)[gLayer.gameWorld getChildByTag:tCharacterManager];
    BirdSprite *bird=[BirdSprite spriteWithSpriteFrameName:@"player01_idle_0000.png"];
    //-------创建动画 ---START
    //3)收集帧列表
    //上升动画 50-51
    NSArray* upAnimFrames=[NSArray arrayWithObjects:
                           [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"player01_jump_0004.png"],
                           [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"player01_jump_0005.png"],
                           [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"player01_jump_0006.png"],
                           nil];
    //4)创建动画对象
    CCAnimation *upAnim = [CCAnimation
                           animationWithSpriteFrames:upAnimFrames delay:0.2f];
    bird.upAction = [CCRepeatForever actionWithAction:
                     [CCAnimate actionWithAnimation:upAnim]];
    NSArray* downAnimFrames=[NSArray arrayWithObjects:
                             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"player01_fall_0010.png"],
                             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"player01_fall_0011.png"],
                             [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"player01_fall_0012.png"],
                             nil];
    //4)创建动画对象
    CCAnimation *downAnim = [CCAnimation
                             animationWithSpriteFrames:downAnimFrames delay:0.2f];
    bird.downAction = [CCRepeatForever actionWithAction:
                       [CCAnimate actionWithAnimation:downAnim ]];
    //-------创建动画 ---END
    
    [bird runAction:bird.downAction];
    
    [spriteSheet addChild:bird z:zBird tag:tBird];
    //CCSprite only supports CCSprites as children when using CCSpriteBatchNode
    bird.layer=gLayer;
    [bird birdEmitterInit];
    
    return bird;
}
+(void)initSpriteSheet:(CCNode*)layer{
    [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:SD_HD_PLIST(@"character.plist")];
    CCSpriteBatchNode *spriteSheet = [CCSpriteBatchNode
                                      batchNodeWithFile:@"character.png"];
    //这里tCharacterManager的z要在tSpriteManager之上，这样此才不会被覆盖
    [layer addChild:spriteSheet z:zBirdSpriteSheet tag:tCharacterManager];
}

-(void)upgradeBird{
    
    if (self.currentGrade++<=MAX_GRADE) {
        [self setTexture:[[CCTextureCache sharedTextureCache] addImage:[NSString stringWithFormat:@"character_%d.png",currentGrade]]];
    }
}

- (void) birdEmitterInit
{ 
    trick_particles = [CCParticleSystemQuad particleWithFile:@"particle_trick.plist"];
    [self.layer.gameWorld addChild:trick_particles z:zBonusParticle];    
    [trick_particles stopSystem];
    
}
-(void)resetParticleSystem{
    //二次撞击金币时候，需要取消上次的emitter，重新开始新的particle
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector( stopParticleSystem) object:nil];
    trick_particles.position=self.position;
    [trick_particles resetSystem];
    if ([SysConfig needAudio]){
        [[SimpleAudioEngine sharedEngine]playEffect:@"boostloop.mp3"];
    }
    [self performSelector:@selector(stopParticleSystem) withObject:self afterDelay:kAWARD_TIME];
    [self performSelector:@selector(stopTrick) withObject:self afterDelay:kAWARD_TIME];
}
-(void)stopParticleSystem{
    [trick_particles stopSystem];
}
-(void)stopTrick{
    ((GameLayer*)layer_).isTrickWorking=NO;
}

#pragma mark move

-(void)changeMoveDirection:(bool)isUp{
    if (isUp) {
        [self stopAction:downAction];
        [self runAction:upAction];
    } else {
        [self stopAction:upAction];
        [self runAction:downAction];
    }
}
- (int)getBonusScore:(unsigned int)tid {
    int tempScore=0;
    switch (tid) {
        case tBlockBounce:
            tempScore=sBlockBounce;
            break;
        case tBlockBreak:
            tempScore=sBlockBreak;
            break;
        case tBlockNormal:
            tempScore=sBlockNormal;
            break;
        case tBlockSpike:
            tempScore=sBlockSpike;
            break;
        case tAwardBump:
            tempScore=sAwardBump;
        case tAwardFlag:
            tempScore=sAwardFlag;
            break;
        case tCoinSmallBlue:
            tempScore=tCoinSmallBlue;
            break;
        case tCoinSmallGold:
            tempScore=sCoinSmallGold;
            break;
        case tCoinBlue:
            tempScore=sCoinBlue;
            break;
        case tCoinGold:
            tempScore=sCoinGold;
            break;
        case tCoinRed:
            tempScore=sCoinRed;
            break;
        case tCoinTrick:
            tempScore=sCoinTrick;
            break;
        default:
            NSLog(@"errir tid:%d !!!!",tid);
            break;
    }
    return tempScore;
}
-(TouchInfo)getTouchInfo:(GameLayer*)ly position:(CGPoint)npt currentTouchInfo:(TouchInfo)ti touchedCoinPos:(NSMutableArray*)cps{
//    CGPoint tilePos= [ly tileCoordinateFromPos:npt];
    unsigned int tid = [ly tileIDFromPosition:npt withLayer:kMAP_LAYER_BONUS];
    if ((tid >=tBlockNormal && tid <=tBlockSpike)) {
//        NSLog(@"----bird position is: %f,%f",self.position.x,self.position.y);
//        NSLog(@"----bird's tile cooridinate is: %f,%f",self.position.x/32,400-self.position.y/32);
//        NSLog(@"----tile collsion is: %f,%f  ,,,, %f,%f",npt.x,npt.y,tilePos.x,tilePos.y);
//        NSLog(@"collision---tid:",tid);
        //检测碰撞,以扣分最少为准
        if (tid<ti.tid) {
            ti.tid= tid;
            ti.position=npt;
        }
        ti.touched=YES;
        
    }else if (tid >=tAwardBump && tid <=tCoinTrick)
    {
        //收集金币和炮弹
//        NSLog(@"----bird tile point is: %f,%f",self.position.x/32,600-self.position.y/32);
        [cps addObject:[NSValue valueWithCGPoint:npt]];
    }
    return ti;
}

/*
 扣分规则
 上碰扣分，下碰不扣,
 左右扣一半分数
 */
//与block检测碰撞的时候，要相应的扩展10px，保证挨着就能算碰撞
- (void) changePositon:(CCLayer *)layer xStep:(float)xStep yStep:(float)yStep{
    GameLayer *ly = (GameLayer *)layer;
    /*
     根据方向，先判断和边界的碰撞,如果边界没有碰撞，bonus才有可能碰撞。
     再判断和bonus的碰撞
     金币的话，上下左右同时检测
     碰撞的话，因为处理不一样，上下为一组，左右为一组分开
     */
    //以下为控制音效所设，和其它没有关系，
    //对于碰撞的分数改变，扣分，在各个if内部判断
    BOOL isJump=NO; //向上jump
    BOOL isCollided=NO; //碰撞block下跌
    BOOL isTouched=NO; //左右碰撞
    BOOL isCoin=NO; //获得金币
    BOOL isBump=NO; //
    BOOL isFlag=NO; //
    
    unsigned int maxTouchGid=-1; //记录碰撞的最大tile gid
    int touchScore=0; //记录碰撞分数
    //记录touch金币的位置，碰撞检查后递归数据得到gid来扣分和改变image
    NSMutableArray* touchedCoinPos=[[[NSMutableArray alloc]initWithCapacity:2]autorelease];
    /*
     碰撞中：
     block的话选择扣分最高的，只有一个
     coin的话，进行累计，有多个
     */
    //HERE self.textureRect.size 是根据texture的大小来定的，也就是当前动画的image大小
    [self setPosition:ccp(self.position.x, self.position.y + yStep)];
    if (yStep>0 ) { //up
        if ([ly gameWorldHeight] - self.position.y < self.textureRect.size.height / 2)
        {
            //先边界碰撞检测
            [self setPosition:ccp(self.position.x, [ly gameWorldHeight] - self.textureRect.size.height / 2)];
        }else{
            //            NSLog(@"from ------up");
            TouchInfo ti={NO,-1,ccp(-1, -1)};
            CGPoint npt1 =ccp(self.position.x, self.position.y + self.textureRect.size.height / 2 );
            ti =[self getTouchInfo:ly position:npt1 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
            CGPoint npt2 =ccp(self.position.x + self.textureRect.size.width *1/ 4, self.position.y + self.textureRect.size.height / 2 );
            ti =[self getTouchInfo:ly position:npt2 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
            //            CGPoint npt3 =ccp(self.position.x + self.textureRect.size.width *2/ 4, self.position.y + self.textureRect.size.height / 2 );
            //            ti =[self getTouchInfo:ly position:npt3 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
            CGPoint npt4 =ccp(self.position.x - self.textureRect.size.width *1/ 4, self.position.y + self.textureRect.size.height / 2 );
            ti =[self getTouchInfo:ly position:npt4 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
            if (IS_IPAD()) {
            CGPoint npt5 =ccp(self.position.x- self.textureRect.size.width *2/ 4, self.position.y + self.textureRect.size.height / 2 );
            ti =[self getTouchInfo:ly position:npt5 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
            }
            //            CGPoint npt6 =ccp(self.position.x- self.textureRect.size.width *3/ 4, self.position.y + self.textureRect.size.height / 2 );
            //            ti =[self getTouchInfo:ly position:npt6 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
            if (ti.touched && !ly.isTrickWorking) {
                isCollided=YES;
                maxTouchGid=ti.tid;
                touchScore=[self getBonusScore:ti.tid];
                
                //tBlockBreak,撞碎block，速度不减
                if (maxTouchGid==tBlockBreak) {
                    
                    CCParticleSystem *particles = [CCParticleSystemQuad particleWithFile:@"break_particle3.plist"];
                    [particles setPosition:ccp(self.position.x, self.position.y+ self.textureRect.size.height )];
                    [ly.gameWorld addChild:particles];
                    
                    CCTMXLayer* tmxLy=[ly.gameWorld layerNamed:kMAP_LAYER_BONUS];
                    CCSprite* tileSprite= [tmxLy tileAt:[ly tileCoordinateFromPos:ti.position]];
                    CCSpriteFrame* frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"block-break-sky02.png"];
                    [tileSprite setDisplayFrame:frame];
                    self.position=ccp(self.position.x, self.position.y+2*self.textureRect.size.height);
                    if ([SysConfig needAudio]){
                    [[SimpleAudioEngine sharedEngine]playEffect:@"block_break.mp3"];
                    }
                }else{
                    //                    self.vel=ccVertexMake(self.vel.x, -(abs(self.vel.y)));
                    self.vel=ccVertexMake(self.vel.x, (abs(self.vel.y))>kVEL_MIN?-(abs(self.vel.y)):-kVEL_MIN);
                    //                    self.vel=ccVertexMake(self.vel.x, -(abs(self.vel.y)+kVEL_MAX));
                    //                    self.position=ccp(self.position.x, self.position.y-self.textureRect.size.height);
                }
                
            }
        }
    }else if(yStep<0){ //down
        if (self.position.y - ly.mapY < self.textureRect.size.height / 2)
        {
            //当前屏幕的底部，而不是地图的底部
            [self setPosition:ccp(self.position.x, self.textureRect.size.height / 2)];
        }else{
            //HERE 这里碰撞检测的x、y坐标偏移值可以初步判断，但由于texture大小不统一，所以需要具体的测试才能精确
//            NSLog(@"from ------down");
            CGFloat cY=self.position.y -(IS_IPAD()?(self.textureRect.size.height*(3/4.0)):(self.textureRect.size.height*(2/4.0)));
            TouchInfo ti={NO,-1};
            CGPoint npt1 =ccp(self.position.x, cY );
            ti =[self getTouchInfo:ly position:npt1 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
            CGPoint npt2 =ccp(self.position.x + self.textureRect.size.width *1/ 4, cY);
            ti =[self getTouchInfo:ly position:npt2 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
//            if (!IS_IPAD()) {
//               CGPoint npt3 =ccp(self.position.x + self.textureRect.size.width *2/ 4, cY);
//                   ti =[self getTouchInfo:ly position:npt3 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
//                CGPoint npt31 =ccp(self.position.x + self.textureRect.size.width *3/ 4, cY);
//                ti =[self getTouchInfo:ly position:npt31 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
//            }
            
            CGPoint npt4 =ccp(self.position.x - self.textureRect.size.width *1/ 4, cY);
            ti =[self getTouchInfo:ly position:npt4 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
             if (IS_IPAD()) {
            CGPoint npt5 =ccp(self.position.x- self.textureRect.size.width *2/ 4, cY);
            ti =[self getTouchInfo:ly position:npt5 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
             }
//             if (!IS_IPAD()) {
//              CGPoint npt6 =ccp(self.position.x- self.textureRect.size.width *3/ 4, cY);
//                        ti =[self getTouchInfo:ly position:npt6 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
//             }
            if (ti.touched && !ly.isTrickWorking) {
                isJump=YES;
                maxTouchGid=ti.tid;
                //tBlockBreak,撞碎block，速度不减
                if (maxTouchGid==tBlockBreak) {
                    /*
                     CCParticleExplosion* emi= [[CustomParticleExplosion share]getEmitterByTexture:@"break_particle2.png" withNode:ly.gameWorld position:ccp(self.position.x, self.position.y+ self.textureRect.size.height )];
                     emi.life=0.3;
                     //                emi.
                     emi.lifeVar=0.3;
                     ccColor4F cStart= {0.8,0.8,0.8,0.8};
                     emi.startColor=cStart;
                     ccColor4F cEnd= {0.5,0.5,0.5,0.8};
                     emi.startColor=cStart;
                     //                emi.startColor= _ccColor4F {0.2,0.2,0.2,0.2};
                     */
                    CCParticleSystem *particles = [CCParticleSystemQuad particleWithFile:@"break_particle3.plist"];
                    [particles setPosition:ccp(self.position.x, self.position.y- self.textureRect.size.height )];
                    [ly.gameWorld addChild:particles];
                    
                    CCTMXLayer* tmxLy=[ly.gameWorld layerNamed:kMAP_LAYER_BONUS];
                    CCSprite* tileSprite= [tmxLy tileAt:[ly tileCoordinateFromPos:ti.position]];
                    CCSpriteFrameCache* cache = [CCSpriteFrameCache sharedSpriteFrameCache];
                    CCSpriteFrame* frame = [cache spriteFrameByName:@"block-break-sky02.png"];
                    [tileSprite setDisplayFrame:frame];
                    self.position=ccp(self.position.x, self.position.y-2*self.textureRect.size.height);
                    if ([SysConfig needAudio]){
                    [[SimpleAudioEngine sharedEngine]playEffect:@"block_break.mp3"];
                    }
                }else{
                    //                    self.vel=ccVertexMake(self.vel.x,-self.vel.y+kVEL_MAX);
                    if (cUSE_Y_ACC) {
                        self.vel=ccVertexMake(self.vel.x, (abs(self.vel.y))>kVEL_MIN?(abs(self.vel.y)):kVEL_MIN);
                    } else {
                        //这里如果墙与墙之间距离很小的话，就没必要加速了吧
                        self.vel=ccVertexMake(self.vel.x, abs(self.vel.x)/2+kVEL_INIT);
                    }
                    
                }
                
                
            }
            
        }
    }
    self.position = ccp(self.position.x + xStep, self.position.y);
    if(xStep<0){ //left
        if ([ly gameWorldWidth] - self.position.x < self.textureRect.size.width / 2)
        {
            [self setPosition:ccp([ly gameWorldWidth] - self.textureRect.size.width / 2, self.position.y)];
            self.vel=ccVertexMake(0, self.vel.y);
        }else{
            //            NSLog(@"from ------left");
            TouchInfo ti={NO,-1};
            CGPoint npt1 =ccp(self.position.x- self.textureRect.size.width / 2 , self.position.y );
            ti =[self getTouchInfo:ly position:npt1 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
            CGPoint npt2 =ccp(self.position.x- self.textureRect.size.width / 2 , self.position.y-self.textureRect.size.height *(IS_IPAD()?1/4:0)  );
            ti =[self getTouchInfo:ly position:npt2 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
            CGPoint npt3 =ccp(self.position.x- self.textureRect.size.width / 2 , self.position.y-self.textureRect.size.height *(IS_IPAD()?2/4:0) );
            ti =[self getTouchInfo:ly position:npt3 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
            CGPoint npt4 =ccp(self.position.x- self.textureRect.size.width / 2 , self.position.y+self.textureRect.size.height *1/ 4 );
            ti =[self getTouchInfo:ly position:npt4 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
            //            CGPoint npt5 =ccp(self.position.x- self.textureRect.size.width / 2 , self.position.y+self.textureRect.size.height *2/ 4 );
            //            ti =[self getTouchInfo:ly position:npt5 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
            if (ti.touched && !ly.isTrickWorking) {
                isTouched=YES;
                maxTouchGid=ti.tid;
                touchScore=[self getBonusScore:ti.tid]/2;
                maxTouchGid=ti.tid;
                //tBlockBreak,撞碎block，速度不减
                if (maxTouchGid==tBlockBreak) {
                    CCParticleSystem *particles = [CCParticleSystemQuad particleWithFile:@"break_particle3.plist"];
                    [particles setPosition:ccp(self.position.x, self.position.y- self.textureRect.size.height )];
                    [ly.gameWorld addChild:particles];
                    
                    CCTMXLayer* tmxLy=[ly.gameWorld layerNamed:kMAP_LAYER_BONUS];
                    CCSprite* tileSprite= [tmxLy tileAt:[ly tileCoordinateFromPos:ti.position]];
                    CCSpriteFrameCache* cache = [CCSpriteFrameCache sharedSpriteFrameCache];
                    CCSpriteFrame* frame = [cache spriteFrameByName:@"block-break-sky02.png"];
                    [tileSprite setDisplayFrame:frame];
                    self.position=ccp(self.position.x-self.textureRect.size.width, self.position.y);
                    if ([SysConfig needAudio]){
                    [[SimpleAudioEngine sharedEngine]playEffect:@"block_break.mp3"];
                    }
                }else{
                    
                    /*
                     //HERE
                     这里速度改变了，但是还有重力感应器在改变速度，所有如果竖直touch墙壁，可能永远出不去
                     */
                    self.vel=ccVertexMake(abs(self.vel.x)*kVEL_HORI_TIME, self.vel.y);
                    self.position=ccp(self.position.x+self.textureRect.size.width/2, self.position.y);
                }
            }
        }
    }else if (xStep>0) { //right
        if (self.position.x - ly.mapX < self.textureRect.size.width / 2)
        {
            [self setPosition:ccp(self.textureRect.size.width / 2, self.position.y)];
             self.vel=ccVertexMake(0, self.vel.y);
        }else{
            //            NSLog(@"from ------right");
//            CGFloat cX=self.position.x+ self.textureRect.size.width*(IS_IPAD()?1/2:) ;
            TouchInfo ti={NO,-1};
            CGPoint npt1 =ccp(self.position.x+ self.textureRect.size.width / 2 , self.position.y );
            ti =[self getTouchInfo:ly position:npt1 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
            CGPoint npt2 =ccp(self.position.x+ self.textureRect.size.width / 2 , self.position.y-self.textureRect.size.height *(IS_IPAD()?1/4 :0) );
            ti =[self getTouchInfo:ly position:npt2 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
            CGPoint npt3 =ccp(self.position.x+ self.textureRect.size.width / 2 , self.position.y-self.textureRect.size.height * (IS_IPAD()?2/ 4 :0) );
            ti =[self getTouchInfo:ly position:npt3 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
            CGPoint npt4 =ccp(self.position.x+ self.textureRect.size.width / 2 , self.position.y+self.textureRect.size.height *1/ 4 );
            ti =[self getTouchInfo:ly position:npt4 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
            //            CGPoint npt5 =ccp(self.position.x+ self.textureRect.size.width / 2 , self.position.y+self.textureRect.size.height *2/ 4 );
            //            ti =[self getTouchInfo:ly position:npt5 currentTouchInfo:ti touchedCoinPos:touchedCoinPos];
            if (ti.touched && !ly.isTrickWorking) {
                isTouched=YES;
                maxTouchGid=ti.tid;
                touchScore=[self getBonusScore:ti.tid]/2;
                //tBlockBreak,撞碎block，速度不减
                if (maxTouchGid==tBlockBreak) {
                    CCParticleSystem *particles = [CCParticleSystemQuad particleWithFile:@"break_particle3.plist"];
                    [particles setPosition:ccp(self.position.x, self.position.y- self.textureRect.size.height )];
                    [ly.gameWorld addChild:particles];
                    
                    CCTMXLayer* tmxLy=[ly.gameWorld layerNamed:kMAP_LAYER_BONUS];
                    CCSprite* tileSprite= [tmxLy tileAt:[ly tileCoordinateFromPos:ti.position]];
                    CCSpriteFrameCache* cache = [CCSpriteFrameCache sharedSpriteFrameCache];
                    CCSpriteFrame* frame = [cache spriteFrameByName:@"block-break-sky02.png"];
                    [tileSprite setDisplayFrame:frame];
                    self.position=ccp(self.position.x+self.textureRect.size.width, self.position.y);
                    if ([SysConfig needAudio]){
                    [[SimpleAudioEngine sharedEngine]playEffect:@"block_break.mp3"];
                    }
                }else{
                    
                    self.vel=ccVertexMake(-abs(self.vel.x)*kVEL_HORI_TIME, self.vel.y);
                    self.position=ccp(self.position.x-self.textureRect.size.width/2, self.position.y);
                }
            }
        }
    }
    ly.score+=touchScore;
    //tBlockSpike的话即扣分，也扣生命
    if (maxTouchGid==tBlockSpike) {
        //        [[PlaySoundUtil sharePlaySoundUtil] playingBgSoundEffectWith:@"spike.wav"];
        if ([SysConfig needAudio]){
            [[SimpleAudioEngine sharedEngine] playEffect:@"spike.wav"];
        }
        ly.life--;
    }
    //检测金币和炮弹
    for (NSValue* v in touchedCoinPos) {
        
        CGPoint npt=[v CGPointValue];
        unsigned int tid=[ly tileIDFromPosition:npt withLayer:kMAP_LAYER_BONUS];
        if (tid==tCoinTrick) {
            [self resetParticleSystem];
            layer_.isTrickWorking=YES;
            self.vel=ccVertexMake(self.vel.x,abs( self.vel.y));//速度向上
            
//            CCSpriteBatchNode *bonusSheet = (CCSpriteBatchNode*)[layer_.gameWorld getChildByTag:tBonusManager];
//            [bonusSheet removeChildByTag:tCoinTrickParticle cleanup:YES];
        }
        
        if (tid>=tCoinSmallBlue&& tid<=tCoinTrick ) {
            isCoin=YES;
            ly.score+=[self getBonusScore:tid];
            CCTMXLayer* tmxLayer=[ly.gameWorld layerNamed:kMAP_LAYER_BONUS];
            CGPoint tilePosition= [ly tileCoordinateFromPos:npt];
            [tmxLayer setTileGID:0 at:tilePosition];
        } else if(tid==tAwardBump && !ly.isTrickWorking) {
            //炸弹
            isBump=YES;
            //TODO 显示爆炸动画,role 闪烁
            ly.score+=[self getBonusScore:tid];
            CCTMXLayer* tmxLayer=[ly.gameWorld layerNamed:kMAP_LAYER_BONUS];
            CGPoint tilePosition= [ly tileCoordinateFromPos:npt];
            [tmxLayer setTileGID:0 at:tilePosition];
            ly.life--;
        }else if(tid==tAwardFlag) {
            isFlag=YES;
            [ly gameOverWin:YES];
            
            //        if (tid==tCoinGold) {
            //            CCSprite* tileSprite= [tmxLayer tileAt:tilePosition];
            //            [tileSprite runAction:[BonusSprite getActionByBonusType:tid]];
            //        }
            
            
        }
    }
    
    
    if (isJump) {
        //        [[PlaySoundUtil sharePlaySoundUtil]playingBgSoundEffectWith:@"jump.wav"];
        if ([SysConfig needAudio]){
            [[SimpleAudioEngine sharedEngine] playEffect:@"jump.wav"];
        }
    }else if (isCollided) {
        //        [[PlaySoundUtil sharePlaySoundUtil]playingBgSoundEffectWith:@"down.wav"];
        if ([SysConfig needAudio]){
            [[SimpleAudioEngine sharedEngine] playEffect:@"down.wav"];
        }
    }else if (isTouched) {
        //        [[PlaySoundUtil sharePlaySoundUtil]playingBgSoundEffectWith:@"touch.wav"];
        if ([SysConfig needAudio]){
            [[SimpleAudioEngine sharedEngine] playEffect:@"touch.wav"];
        }
    }
    if (isCoin) {
        //        [[PlaySoundUtil sharePlaySoundUtil]playingBgSoundEffectWith:@"coin.wav"];
        if ([SysConfig needAudio]){
            [[SimpleAudioEngine sharedEngine] playEffect:@"coin.wav"];
        }
    }else if(isBump){
        if ([SysConfig needAudio]){
            [[SimpleAudioEngine sharedEngine] playEffect:@"bump.mp3"];
        }
        [self runAction:[CCBlink actionWithDuration:2 blinks:10]];
    }else if(isFlag){
        if ([SysConfig needAudio]){
            [[SimpleAudioEngine sharedEngine] playEffect:@"gamewin.wav"];
        }
    }
    
    
}
@end
