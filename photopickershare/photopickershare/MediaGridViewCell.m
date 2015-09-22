

#import "MediaGridViewCell.h"




@interface MediaGridViewCell ()
@property (strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *mediaLabel;
@property (nonatomic, strong) UIView *bg;
@property (strong) UIImageView *videoIcon;



@end

@implementation MediaGridViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.imageView setClipsToBounds:YES];
        [self addSubview:self.imageView];
        
        
        self.bg = [[UIView alloc]initWithFrame:CGRectMake(0, self.frame.size.height -18, self.frame.size.width, 18)];
        self.bg.backgroundColor = [UIColor colorWithRed:0. green:0. blue:0. alpha:.7];
        self.bg.hidden = YES;
        [self addSubview:self.bg];
        
        self.mediaLabel=[[UILabel alloc]initWithFrame:CGRectMake(0, self.frame.size.height -16, self.frame.size.width-3, 12)];
        self.mediaLabel.textAlignment = NSTextAlignmentRight;
        self.mediaLabel.textColor = [UIColor whiteColor];
        self.mediaLabel.font =  [UIFont systemFontOfSize:12.];
        self.mediaLabel.hidden = YES;
        
        [self addSubview:self.mediaLabel];

        self.videoIcon = [[UIImageView alloc] initWithFrame:CGRectMake(3, self.frame.size.height -15, 20, 10)];
        self.videoIcon.image = [UIImage imageNamed:@"videoIcon.png"];
        self.videoIcon.contentMode = UIViewContentModeScaleAspectFill;
        self.videoIcon.hidden = YES;

        [self addSubview:self.videoIcon];
        
        
        
    }
    
    return self;
    
}

- (void)setThumbnailImage:(UIImage *)thumbnailImage {
    _thumbnailImage = thumbnailImage;
    self.imageView.image = thumbnailImage;
}

- (void) setMediaType:(MediaFileType)mediaFileType withDuration:(NSTimeInterval)duration {
    
    //MediaFileTypeImage,
    
    if (mediaFileType == MediaFileTypeVideo ) {
        self.bg.hidden = NO;
        self.mediaLabel.hidden = NO;
        self.videoIcon.hidden = NO;

        self.mediaLabel.text = [self stringFromInterval2:duration];
        
    }
    
    if (mediaFileType == MediaFileTypeGif ) {
        self.bg.hidden = NO;
        self.mediaLabel.hidden = NO;
        self.mediaLabel.text = @"GIF";
        
    }
    
    
}


- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}

- (NSString *)stringFromInterval2:(NSTimeInterval)timeInterval
{
#define SECONDS_PER_MINUTE (60)
#define MINUTES_PER_HOUR (60)
#define SECONDS_PER_HOUR (SECONDS_PER_MINUTE * MINUTES_PER_HOUR)
#define HOURS_PER_DAY (24)
    
    // convert the time to an integer, as we don't need double precision, and we do need to use the modulous operator
    int ti = round(timeInterval);
    
        return [NSString stringWithFormat:@"%.2d:%.2d",  (ti / SECONDS_PER_MINUTE) % MINUTES_PER_HOUR, ti % SECONDS_PER_MINUTE];
    
  //  return [NSString stringWithFormat:@"%.2d:%.2d:%.2d", (ti / SECONDS_PER_HOUR) % HOURS_PER_DAY, (ti / SECONDS_PER_MINUTE) % MINUTES_PER_HOUR, ti % SECONDS_PER_MINUTE];
    
#undef SECONDS_PER_MINUTE
#undef MINUTES_PER_HOUR
#undef SECONDS_PER_HOUR
#undef HOURS_PER_DAY
}

@end


