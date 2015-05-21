//
//  HomeViewController.m
//  VuforiaSamples
//
//  Created by Alberto Quesada on 10/4/15.
//  Copyright (c) 2015 Qualcomm. All rights reserved.
//

#import "HomeViewController.h"
#import "AboutViewController.h"
#import "SampleAppSlidingMenuController.h"
#import "SampleAppMenu.h"
//#import "ImageTargetsViewController.h"

@interface HomeViewController ()

@property(strong, nonatomic) IBOutlet UILabel *titleL; // label de título
@property(strong, nonatomic) IBOutlet UIButton *camera; // boton que lleva a la cámara
@property(strong, nonatomic) IBOutlet UIButton *about; // boton que lleva a about
@property(strong, nonatomic) IBOutlet UIImageView *background; // imagen de fondo de la vista

@end

@implementation HomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //[self.titleL setText:NSLocalizedString(@"TITLE", nil)];
    
    //self.background.image = [UIImage imageNamed:@"homeBackground.png"];
    [self.titleL setText:@"BarChecker"];
    [self.camera setTitle:@"Detectar" forState:UIControlStateNormal];
    [self.about setTitle:@"Sobre Nosotros" forState:UIControlStateNormal];
    //[self.camera setBackgroundImage:[UIImage imageNamed:@"greyButton.png"] forState:UIControlStateNormal];
    //[self.about setBackgroundImage:[UIImage imageNamed:@"greyButton.png"] forState:UIControlStateNormal];

    [[self navigationController] setNavigationBarHidden:YES animated:NO];
    
}

-(void) viewWillAppear:(BOOL)animated {
    [[self navigationController] setNavigationBarHidden:YES animated:YES];

}

- (IBAction)cameraButton:(id)sender {
    
    Class vcClass = NSClassFromString(@"ImageTargetsViewController");
    id vc = [[vcClass alloc]  initWithNibName:nil bundle:nil];
    
    SampleAppSlidingMenuController *slidingMenuController = [[SampleAppSlidingMenuController alloc] initWithRootViewController:vc];
    
    [self.navigationController pushViewController:slidingMenuController animated:NO];
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Back" style: UIBarButtonItemStyleBordered target:nil action:nil] autorelease];

    [slidingMenuController release];
    [vc release]; // don't leak memory
    
    //[self.navigationController pushViewController:vc animated:NO];
    
    
    
    /*AuxViewController *vc = [[AuxViewController alloc] initWithNibName:@"AuxViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
    
    //self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Back" style: UIBarButtonItemStyleBordered target:nil action:nil] autorelease];
    

    
*/
}

- (IBAction)aboutButton:(id)sender {
    
    AboutViewController *vc = [[AboutViewController alloc] initWithNibName:@"AboutViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
    
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Back" style: UIBarButtonItemStyleBordered target:nil action:nil] autorelease];

}

@end