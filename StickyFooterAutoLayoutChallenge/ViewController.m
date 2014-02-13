//
//  ViewController.m
//  StickyFooterAutoLayoutChallenge
//
//  Created by Andrew Black on 2/12/14.
//  Copyright (c) 2014 Andrew Black. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) UIView *stickyFooterView;
@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic) UIFont *textViewFont;

@property (strong, nonatomic) NSLayoutConstraint *textViewHeightConstraint;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.scrollView.alwaysBounceVertical = YES;
    
    [self.scrollView addSubview:self.contentView];
    [self.contentView addSubview:self.textView];
    [self.contentView addSubview:self.stickyFooterView];
    
    [self configureConstraintsForContentViewSubviews];
    
    CGFloat contentHeight = [self contentHeightForContentViewWithString:self.textView.text];
    CGSize boundsSize = self.view.bounds.size;
    if (contentHeight < self.view.bounds.size.height) {
        self.contentView.frame = CGRectMake(0, 0, boundsSize.width, boundsSize.height);
    } else {
        self.contentView.frame = CGRectMake(0, 0, boundsSize.width, contentHeight);
    }

    self.scrollView.contentSize = self.contentView.bounds.size;
}

#define TOP_MARGIN 24
#define BOTTOM_MARGIN 8
#define SIDE_MARGIN 8
#define FOOTER_HEIGHT 50
#define MIN_SPACE_BETWEEN_SUBVIEWS 25

- (void)configureConstraintsForContentViewSubviews
{
    assert(_textView && _stickyFooterView);
    
    NSString *format = @"H:|-(space)-[textView]-(space)-|";
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:@{@"space": @(SIDE_MARGIN)} views:@{@"textView": _textView}]];
    
    format = @"H:|-(space)-[footer]-(space)-|";
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:@{@"space": @(SIDE_MARGIN)} views:@{@"footer": _stickyFooterView}]];
    
    format = @"V:|-(space)-[textView]";
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:@{@"space": @(TOP_MARGIN)} views:@{@"textView": _textView}]];
    
    format = @"V:[footer(height)]-(space)-|";
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:@{@"space": @(BOTTOM_MARGIN), @"height": @(FOOTER_HEIGHT)} views:@{@"footer": _stickyFooterView}]];
    
    // a UITextView does not have an intrinsic content size; will need to install an explicit height constraint based on size of content
    UITextView *mockTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width - 2 * SIDE_MARGIN, FLT_MAX)];
    assert(self.textView.text);
    mockTextView.font = self.textViewFont;
    mockTextView.text = self.textView.text;
    [mockTextView sizeToFit];
    
    self.textViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0f constant:mockTextView.bounds.size.height];
    
    [self.textView addConstraint:self.textViewHeightConstraint];
}

- (CGFloat)contentHeightForContentViewWithString:(NSString *)string
{
    UITextView *mockTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width - 2 * SIDE_MARGIN, FLT_MAX)];
    assert(self.textView.text);
    mockTextView.font = self.textViewFont;
    mockTextView.text = string;
    [mockTextView sizeToFit];
    
    return TOP_MARGIN + mockTextView.bounds.size.height + MIN_SPACE_BETWEEN_SUBVIEWS + FOOTER_HEIGHT + BOTTOM_MARGIN;
}

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = [UIColor greenColor];
    }
    return _contentView;
}

- (UIView *)stickyFooterView
{
    if (!_stickyFooterView) {
        _stickyFooterView = [[UIView alloc] init];
        _stickyFooterView.translatesAutoresizingMaskIntoConstraints = NO;
        _stickyFooterView.backgroundColor = [UIColor blueColor];
        
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        recognizer.numberOfTapsRequired = 2;
        [_stickyFooterView addGestureRecognizer:recognizer];
        
    }
    return _stickyFooterView;
}

- (UITextView *)textView
{
    if (!_textView) {
        _textView = [[UITextView alloc] init];
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
        _textView.scrollEnabled = NO;
        _textView.delegate = self;
        _textView.backgroundColor = [UIColor lightGrayColor];
        _textView.font = self.textViewFont;
        _textView.text = @"All work and no play makes Jack a dull boy. All work and no play makes Jack a dull boy. All work and no play makes Jack a dull boy. All work and no play makes Jack a dull boy.";
    }
    return _textView;
}

- (UIFont *)textViewFont
{
    if (!_textViewFont) {
        _textViewFont = [UIFont fontWithName:@"Helvetica Neue" size:24];
    }
    return _textViewFont;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardUp:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDown:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - UITextViewDelegate
/*
- (void)textViewDidChangeSelection:(UITextView *)textView
{
    if (!self.isKeyboardUp) {
        return;
    }
    
    NSLog(@"%@", NSStringFromSelector(_cmd));
    
    NSRange glyphRange;
    [self.textView.layoutManager characterRangeForGlyphRange:textView.selectedRange actualGlyphRange:&glyphRange];
    CGRect rect = [self.textView.layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:self.textView.textContainer];
    
    NSLog(@"bounding rect for selection = %@", NSStringFromCGRect(rect));
    
    CGRect convertedRect = [self.textView convertRect:rect toView:self.scrollView];
    
    NSLog(@"converted rect = %@", NSStringFromCGRect(convertedRect));
    
    [self.scrollView scrollRectToVisible:convertedRect animated:YES];
}*/

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    UITextView *mockTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width - 2 * SIDE_MARGIN, FLT_MAX)];
    assert(self.textView.text);
    mockTextView.font = self.textViewFont;
    
    mockTextView.text = [textView.text stringByReplacingCharactersInRange:range withString:text];
    [mockTextView sizeToFit];
    
    self.textViewHeightConstraint.constant = mockTextView.bounds.size.height;
    
    CGFloat contentHeight = [self contentHeightForContentViewWithString:mockTextView.text];
    CGSize boundsSize = self.view.bounds.size;
    
    self.contentView.frame = CGRectMake(0, 0, boundsSize.width, contentHeight);
    self.scrollView.contentSize = self.contentView.bounds.size;
    
    return YES;
}

#pragma mark - action methods

- (void)keyboardUp:(NSNotification *)notification
{
    CGFloat contentHeight = [self contentHeightForContentViewWithString:self.textView.text];
    CGSize boundsSize = self.view.bounds.size;
    
    NSDictionary *info = [notification userInfo];
    CGRect keyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    double duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration animations:^{
        self.contentView.frame = CGRectMake(0, 0, boundsSize.width, contentHeight);
        self.scrollView.contentSize = self.contentView.bounds.size;
        self.scrollView.contentInset = UIEdgeInsetsMake(0, 0, keyboardRect.size.height, 0);
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardDown:(NSNotification *)notification
{
    // a UITextView does not have an intrinsic content size; will need to install an explicit height constraint based on size of content
    UITextView *mockTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width - 2 * SIDE_MARGIN, FLT_MAX)];
    assert(self.textView.text);
    mockTextView.font = self.textViewFont;
    mockTextView.text = self.textView.text;
    [mockTextView sizeToFit];
    
    CGFloat contentHeight = [self contentHeightForContentViewWithString:self.textView.text];
    CGSize boundsSize = self.view.bounds.size;
    
    NSDictionary *info = [notification userInfo];
    double duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration animations:^{
        
        if (contentHeight < self.view.bounds.size.height) {
            self.contentView.frame = CGRectMake(0, 0, boundsSize.width, boundsSize.height);
        } else {
            self.contentView.frame = CGRectMake(0, 0, boundsSize.width, contentHeight);
        }
        
        self.scrollView.contentSize = self.contentView.bounds.size;
        self.scrollView.contentInset = UIEdgeInsetsZero;
        
        self.textViewHeightConstraint.constant = mockTextView.bounds.size.height;
        
        [self.view layoutIfNeeded];
    }];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer
{
    [self.textView resignFirstResponder];
}


@end









