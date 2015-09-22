
@import UIKit;

typedef NS_ENUM(NSInteger, MediaFileType) {
    MediaFileTypeImage,
    MediaFileTypeVideo,
    MediaFileTypeGif
};


@interface MediaGridViewCell : UICollectionViewCell

@property (nonatomic, strong) UIImage *thumbnailImage;

- (void) setMediaType:(MediaFileType)mediaFileType withDuration:(NSTimeInterval)duration;

@end
