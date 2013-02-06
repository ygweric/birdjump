#import "Main.h"
#import <mach/mach_time.h>
//根据当前时间定义随机数种子
#define RANDOM_SEED() srandom((unsigned)(mach_absolute_time() & 0xFFFFFFFF))

@interface Main(Private)
- (void)initClouds;
- (void)initCloud;
@end


@implementation Main

- (id)init {
//	NSLog(@"Main::init");
	
	if(![super init]) return nil;
	//定义随机数种子
	RANDOM_SEED();

    //The capacity will be increased in 33% in runtime if it run out of space.
	CCSpriteBatchNode *batchNode = [CCSpriteBatchNode batchNodeWithFile:@"sprites.png" capacity:10];
	[self addChild:batchNode z:-1 tag:kSpriteManager];

	CCSprite *background = [CCSprite spriteWithTexture:[batchNode texture] rect:CGRectMake(0,0,320,480)];
	[batchNode addChild:background];
	background.position = CGPointMake(160,240);

    //生成kNumClouds个cloud 并随即防灾合适的位置
	[self initClouds];

	[self schedule:@selector(step:)];
	
	return self;
}

- (void)dealloc {
//	NSLog(@"Main::dealloc");
	[super dealloc];
}

- (void)initClouds {
//	NSLog(@"initClouds");
	
	currentCloudTag = kCloudsStartTag;
	while(currentCloudTag < kCloudsStartTag + kNumClouds) {
		[self initCloud];
		currentCloudTag++;
	}
	
	[self resetClouds];
}

- (void)initCloud {
	
	CGRect rect;
    //随机选择一朵云
	switch(random()%3) {
		case 0: rect = CGRectMake(336,16,256,108); break;
		case 1: rect = CGRectMake(336,128,257,110); break;
		case 2: rect = CGRectMake(336,240,252,119); break;
	}	
	
	CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
	CCSprite *cloud = [CCSprite spriteWithTexture:[batchNode texture] rect:rect];
	[batchNode addChild:cloud z:3 tag:currentCloudTag];
	
    //透明度
	cloud.opacity = 128;
}

- (void)resetClouds {
//	NSLog(@"resetClouds");
	
	currentCloudTag = kCloudsStartTag;
	
	while(currentCloudTag < kCloudsStartTag + kNumClouds) {
		[self resetCloud];

		CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
		CCSprite *cloud = (CCSprite*)[batchNode getChildByTag:currentCloudTag];
		CGPoint pos = cloud.position;
        //y原本是 scaled_width/2 + 480~ 480*2-scaled_width，
        //现在成为 scaled_width/2~ 480-scaled_width
        //这里应该可以和resetCloud()的位置变换放在一块
		pos.y -= 480.0f;
		cloud.position = pos;
		
		currentCloudTag++;
	}
}

- (void)resetCloud {
	
	CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
	CCSprite *cloud = (CCSprite*)[batchNode getChildByTag:currentCloudTag];
	//设置cloud的远近距离 5~25
	float distance = random()%20 + 5;
	//scale范围 1-5
	float scale = 5.0f / distance;
	cloud.scaleX = scale;
	cloud.scaleY = scale;
    //cloud是否水平翻转
	if(random()%2==1) cloud.scaleX = -cloud.scaleX;
	
	CGSize size = cloud.contentSize;
	float scaled_width = size.width * scale;
    //x范围是- scaled_width/2 ~ 320+ scaled_width/2，因此cloud可能只显示一个小角
	float x = random()%(320+(int)scaled_width) - scaled_width/2;
    //y是 scaled_width/2 + 480~ 480*2-scaled_width  不知道什么用
	float y = random()%(480-(int)scaled_width) + scaled_width/2 + 480;
	
	cloud.position = ccp(x,y);
}

- (void)step:(ccTime)dt {
//	NSLog(@"Main::step");
	
	CCSpriteBatchNode *batchNode = (CCSpriteBatchNode*)[self getChildByTag:kSpriteManager];
	
	int t = kCloudsStartTag;
	for(t; t < kCloudsStartTag + kNumClouds; t++) {
		CCSprite *cloud = (CCSprite*)[batchNode getChildByTag:t];
		CGPoint pos = cloud.position;
		CGSize size = cloud.contentSize;
        //x最表逐渐右移，模仿吹风效果
		pos.x += 0.1f * cloud.scaleY;
        //如果超过了最右边，则从最左边重新开始
		if(pos.x > 320 + size.width/2) {
			pos.x = -size.width/2;
		}
		cloud.position = pos;
	}
	
}

@end
