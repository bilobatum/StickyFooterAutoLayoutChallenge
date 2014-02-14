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
    
    // Apple's mixed (a.k.a. hybrid) approach to laying out a scroll view with Auto Layout: explicitly set content view's frame and scroll view's contentSize (see Apple's Technical Note TN2154: https://developer.apple.com/library/ios/technotes/tn2154/_index.html)
    CGFloat textViewHeight = [self calculateHeightForTextViewWithString:self.textView.text];
    CGFloat contentViewHeight = [self calculateHeightForContentViewWithTextViewHeight:textViewHeight];
    // scroll view is fullscreen in storyboard; i.e., it's final on-screen geometries will be the same as the view controller's main view; unfortunately, the scroll view's final on-screen geometries are not available in viewDidLoad
    CGSize scrollViewSize = self.view.bounds.size;
    
    if (contentViewHeight < scrollViewSize.height) {
        self.contentView.frame = CGRectMake(0, 0, scrollViewSize.width, scrollViewSize.height);
    } else {
        self.contentView.frame = CGRectMake(0, 0, scrollViewSize.width, contentViewHeight);
    }

    self.scrollView.contentSize = self.contentView.bounds.size;
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

#pragma mark - private helper methods

#define TOP_MARGIN 24
#define BOTTOM_MARGIN 8
#define SIDE_MARGIN 8
#define FOOTER_HEIGHT 50
#define MIN_SPACE_BETWEEN_SUBVIEWS 25

- (void)configureConstraintsForContentViewSubviews
{
    assert(_textView && _stickyFooterView); // for debugging
    
    // note: there is no constraint between the subviews along the vertical axis; the amount of vertical space between the subviews is determined by the content view's height
    
    NSString *format = @"H:|-(space)-[textView]-(space)-|";
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:@{@"space": @(SIDE_MARGIN)} views:@{@"textView": _textView}]];
    
    format = @"H:|-(space)-[footer]-(space)-|";
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:@{@"space": @(SIDE_MARGIN)} views:@{@"footer": _stickyFooterView}]];
    
    format = @"V:|-(space)-[textView]";
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:@{@"space": @(TOP_MARGIN)} views:@{@"textView": _textView}]];
    
    format = @"V:[footer(height)]-(space)-|";
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:format options:0 metrics:@{@"space": @(BOTTOM_MARGIN), @"height": @(FOOTER_HEIGHT)} views:@{@"footer": _stickyFooterView}]];
    
    // a UITextView does not have an intrinsic content size; will need to install an explicit height constraint based on the size of the text; when the text is modified, this height constraint's constant will need to be updated
    CGFloat textViewHeight = [self calculateHeightForTextViewWithString:self.textView.text];
    
    self.textViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.textView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0f constant:textViewHeight];
    
    [self.textView addConstraint:self.textViewHeightConstraint];
}

// called when UITextView's text is modified
- (void)updateLayoutForNewString:(NSString *)string
{
    assert(self.textViewHeightConstraint); // for debugging
    
    CGFloat textViewHeight = [self calculateHeightForTextViewWithString:string];
    self.textViewHeightConstraint.constant = textViewHeight;
    
    CGFloat contentViewHeight = [self calculateHeightForContentViewWithTextViewHeight:textViewHeight];
    CGSize scrollViewSize = self.scrollView.bounds.size;
    
    self.contentView.frame = CGRectMake(0, 0, scrollViewSize.width, contentViewHeight);
    self.scrollView.contentSize = self.contentView.bounds.size;
}

- (CGFloat)calculateHeightForContentViewWithTextViewHeight:(CGFloat)textViewHeight
{
    return TOP_MARGIN + textViewHeight + MIN_SPACE_BETWEEN_SUBVIEWS + FOOTER_HEIGHT + BOTTOM_MARGIN;
}

// calculate height for expandable UITextView
- (CGFloat)calculateHeightForTextViewWithString:(NSString *)string
{
    UITextView *mockTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width - 2 * SIDE_MARGIN, FLT_MAX)];
    mockTextView.font = self.textViewFont;
    mockTextView.text = string;
    [mockTextView sizeToFit];
    
    return mockTextView.bounds.size.height;
}

- (void)scrollToCaret
{
    UITextPosition *caretPosition = [self.textView positionFromPosition:self.textView.beginningOfDocument offset:self.textView.selectedRange.location];
    CGRect caretRect = [self.textView caretRectForPosition:caretPosition];
    
    CGRect convertedRect = [self.textView convertRect:caretRect toView:self.contentView];
    
    [self.scrollView scrollRectToVisible:convertedRect animated:YES];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *newString = [textView.text stringByReplacingCharactersInRange:range withString:text];
    [self updateLayoutForNewString:newString];
    
    return YES;
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    [self scrollToCaret];
}

#pragma mark - action methods

- (void)keyboardUp:(NSNotification *)notification
{
    // when the keyboard appears, extraneous vertical space between the subviews is eliminated–if necessary; i.e., vertical space between the subviews is reduced to the minimum if this space is not already at the minimum
    
    NSDictionary *info = [notification userInfo];
    CGRect keyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    double duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGFloat contentViewHeight = [self calculateHeightForContentViewWithTextViewHeight:self.textView.bounds.size.height];
    CGSize scrollViewSize = self.scrollView.bounds.size;
    
    [UIView animateWithDuration:duration animations:^{
        
        self.contentView.frame = CGRectMake(0, 0, scrollViewSize.width, contentViewHeight);
        self.scrollView.contentSize = self.contentView.bounds.size;
        UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, keyboardRect.size.height, 0);
        self.scrollView.contentInset = insets;
        self.scrollView.scrollIndicatorInsets = insets;
        
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        
        [self scrollToCaret];
    }];
}

- (void)keyboardDown:(NSNotification *)notification
{
    // when the keyboard dissappears, extraneous vertical space between the subviews may be re-introduced
    
    CGFloat contentViewHeight = [self calculateHeightForContentViewWithTextViewHeight:self.textView.bounds.size.height];
    CGSize scrollViewSize = self.scrollView.bounds.size;
    NSDictionary *info = [notification userInfo];
    double duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        
        if (contentViewHeight < scrollViewSize.height) {
            self.contentView.frame = CGRectMake(0, 0, scrollViewSize.width, scrollViewSize.height);
        } else {
            self.contentView.frame = CGRectMake(0, 0, scrollViewSize.width, contentViewHeight);
        }
        
        self.scrollView.contentSize = self.contentView.bounds.size;
        self.scrollView.contentInset = UIEdgeInsetsZero;
        self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
        
        [self.view layoutIfNeeded];
    }];
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer
{
    [self.textView resignFirstResponder];
}

#pragma mark - getters for private API

// the scroll view's container view
- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = [UIColor orangeColor];
    }
    return _contentView;
}

- (UIView *)stickyFooterView
{
    if (!_stickyFooterView) {
        _stickyFooterView = [[UIView alloc] init];
        _stickyFooterView.translatesAutoresizingMaskIntoConstraints = NO;
        _stickyFooterView.backgroundColor = [UIColor blueColor];
        
        // will dismiss keyboard in response to double tapping the sticky footer; this is totally arbitrary
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
        _textView.scrollEnabled = NO; // text view's height will expand so all text is visible
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

@end









