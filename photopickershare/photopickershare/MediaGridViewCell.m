

#import "MediaGridViewCell.h"

@interface MediaGridViewCell ()
@property (strong) IBOutlet UIImageView *imageView;
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
        
        
    }
    
    return self;
    
}

- (void)setThumbnailImage:(UIImage *)thumbnailImage {
    _thumbnailImage = thumbnailImage;
    self.imageView.image = thumbnailImage;
}

@end


