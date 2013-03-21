//-----------------CONST STRING START
//#define cNEED_SOUND YES
#define cNEED_SOUND NO

//是否使用y方向的加速机制
//#define cUSE_Y_ACC YES
#define cUSE_Y_ACC NO

#define UDF_AUDIO @"UDF_AUDIO"
#define UDF_MUSIC @"UDF_MUSIC"
#define UDF_DIFFICULLY @"UDF_DIFFICULLY"
#define UDF_OPERATION @"UDF_OPERATION"
#define UDF_LEVEL_SELECTED @"UDF_LEVEL_SELECTED" //选择level，及当前正玩level
#define UDF_LEVEL_PASSED @"UDF_LEVEL_PASSED" //已通过最大level
#define UDF_LEVEL_CURRENT @"UDF_LEVELCURRENT" //当前正玩或刚刚结束level，先不用，以后或许会需要
#define UDF_TOTAL_SCORE @"UDF_TOTAL_SCORE" //用户积分

/*
 这些系统配置静态变量需要在app启动的时候读取userdefault初始化
 当usedefault改变后，需要修改相应的变量
 设置静态变量，是为了防止多次读取userdefault而造成资源占用 
 */

#define kMAP_LAYER_BONUS  @"bonus"

//-----------------CONST STRING END


//#define RESET_DEFAULTS
//帧频率
#define kFPS 60

//-----------------BIRD START
#define kVEL_INIT (IS_IPAD?300.0f:150) //初始速度 600
#define kVEL_MAX kVEL_INIT //最大速度=初始速度+xx
#define kVEL_MIN 60.0f //最小速度，y方向碰撞后的速度
#define kACC -20.0f  //-450.0f
//需要符合约束500<KACC_SCALE*kVEL_MIN ，是为了防止role掉进blcok中
//重力感应时候的比重-加速度，越大，y轴加速度越小,只有在启动y加速的时候才会有用
#define KACC_SCALE 10 
#define kVEL_HORI_TIME 1 //水平碰撞时候速度增加倍数



//-----------------BIRD END
//###############################
//-----------------GAME START
#define kLIFE_INIT 3
#define kLIFE_SCORE_SCALE 1000 //每kLIFE_SCORE_SCALE，life加一,仅限与当前关卡
#define kLIFE_TOTAL_SCORE_SCALE 5000 //每kLIFE_TOTAL_SCORE_SCALE，life永久加一，所有关卡--，暂时不用
#define kLIFE_LEVEL_SCALE 3 //每过kLIFE_LEVEL_SCALE关，life加一，永久性，所有关卡
#define kAWARD_TIME 5
#define kGAME_SCORE_MODEL @"score: %d\nlife:%d "
#define kWIN_SCORE_MODEL @"score: %d "
#define kGAME_AFTER_DELAY 1

//scan map的时长和步长，二选一
#define kGAME_MAP_SCAN_TIME 15
/*
 ipad 12.0，tile200层，大概需要20秒钟，即(36*200)/(12*60)=10，来回=20
 */
#define kGAME_MAP_SCAN_STEP IS_IPAD?12.0f:12.0f

//FIXME release
#define kMAX_LEVEL_IDEAL 13
#define kMAX_LEVEL_REAL 13

//-----------------GAME END

//sprite tag
enum {
    tGameWorldMap,
	tSpriteManager,
    tBonusManager,
    tCharacterManager, //管理character
     tButtonManager, 
	tBird,
	tScoreLabel,
    //kNumClouds个cloud的第一个tag
	tCloudsStartTag = 100,
	tPlatformsStartTag = 200,
    tBonusCoinNormalStartTag=400,
};
// layer z
enum{
    zBgSpriteSheet,
    zBg,
    zCloud,
    zGameWorldMap,
    zPlatform,
    zParticleExplosion,
    zBirdSpriteSheet,
    zBird,
    zBonusSpriteSheet,
    zBonus,
    zBonusParticle,
    zScoreLablel,
     zButtonSpriteSheet,
    zBelowOperation,
    zPauseLayer,
    zAboveOperation,
    
};

typedef enum{
    UP,
    DOWN,
    LEFT,
    RIGHT,
}DIRECTION ;

//bonus tag
typedef enum{
    //block
    tBlockNormal=1,
    tBlockBounce,
    tBlockBreak,    
    tBlockSpike,
    tAwardBump,
    tAwardFlag,
    //coin
    tCoinSmallBlue,
    tCoinSmallGold,    
    tCoinBlue,
    tCoinGold,    
    tCoinRed,
    tCoinTrick,
    tCoinTrickParticle,
//    kCountBonus,
    
}BonusType ;

//tile score 
enum{
    //block
    sBlockNormal=0,
    sBlockBounce=-1,
    sBlockBreak=-2,
    sBlockSpike=-5,
    sAwardBump=-20,
    sAwardFlag=100,
    //coin
    sCoinSmallBlue=1,
    sCoinSmallGold=2,
    sCoinGold=3,
    sCoinBlue=4,
    sCoinRed=5,
    sCoinTrick=6,
} ;

//ad
#define UFK_SHOW_AD @"UFK_SHOW_AD"
#define kTAG_Ad_VIEW 1101
#define KEY_AD_ADWHIRL_IPHONE @"fbe17db0128f450f93c96394c68318dc"
#define KEY_AD_ADWHIRL_IPAD @"b781bd662cce44369ba283b9d425e3b2"
#define KEY_UMENG_IPHONE @"514b18b952701548c8000005"
#define KEY_UMENG_IPAP @"514b19115270153b26000001"
//launch
#define HAVE_SETTED @"HAVE_SETTED"
#define IS_FAMILY_PLAY @"IS_FAMILY_PLAY"
#define UFK_CURRENT_VERSION @"UFK_CURRENT_VERSION"
//rate
#define UFK_LAST_TIME @"UFK_LAST_TIME"
#define UFK_NEXT_ALERT_RATE_TIME @"UFK_NEXT_ALERT_RATE_TIME"
#define UFK_TOTAL_LAUNCH_COUNT @"UFK_TOTAL_LAUNCH_COUNT"

#define kRATE_FIRST_TIME 3 //首次运行n次后提醒评分 5
#define kRATE_DAYS 5*24*60*60    //距离上次评分n天后再次提醒评分 5*24*60*60
#define kRATE_MAX_DAYS kRATE_DA
