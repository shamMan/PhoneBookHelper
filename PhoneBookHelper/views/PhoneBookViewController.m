//
//  PhoneBookViewController.m
//  PhoneBookHelper
//
//  Created by ShawLiao on 13-5-13.
//  Copyright (c) 2013年 ShawLiao. All rights reserved.
//

#import "PhoneBookViewController.h"
#import "Contacts.h"
#import "SearchHelpr.h"
#import "pinyin.h"

@interface PhoneBookViewController ()<UISearchBarDelegate>
@property (retain, nonatomic) UISearchBar*  searchBar;
@property (retain, nonatomic) UISearchDisplayController* searchDC;
// 搜索结果列表，值为 包含 ContractItem 的 NSArray
@property (retain, nonatomic) NSArray*          searchResult;
@property (retain, nonatomic) SearchHelper*     searchHelper;
@property (retain, nonatomic) NSMutableArray*   sectionArray;
@end

@implementation PhoneBookViewController

#pragma mark - Getter & Setter
- (SearchHelper*)searchHelper
{
    if (!_searchHelper) {
        _searchHelper   =   [[SearchHelper alloc] init];
    }
    return _searchHelper;
}

- (void)dealloc
{
    [_searchBar release];
    [_searchDC release];
    [_searchResult release];
    [_searchHelper release];
    [_sectionArray release];
    return [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self)
    {
        // Custom initialization
        
        self.searchHelper.sourceArray   =   [ContactsList sharedContactsList].recordList;
        self.searchHelper.searchBlock   =   ^(NSArray* source,NSString* keywords)
        {
            // 1 以 pinyinName 查找匹配
            NSMutableArray* array   =   [NSMutableArray arrayWithArray:source];
            NSPredicate* predicate_1 = [NSPredicate predicateWithFormat:@"pinyinName CONTAINS[cd] %@", keywords];
            // 2 以 displayName 查找匹配
            NSPredicate* predicate_2 = [NSPredicate predicateWithFormat:@"displayName CONTAINS[cd] %@",keywords];
            // 3 以 手机号码查找
            NSPredicate* predicate_3 = [NSPredicate predicateWithFormat:@"mobileNumber CONTAINS[cd] %@",keywords];
            NSPredicate* predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[predicate_1, predicate_2,predicate_3]];
            [array filterUsingPredicate:predicate];
            return array;
        };
        
        self.sectionArray   =   [[[NSMutableArray alloc] initWithCapacity:26] autorelease];
        for (int i=0; i<27; i++) {
            [self.sectionArray addObject:[NSMutableArray array]];
        }
        
        for (ContactsItem* item in [ContactsList sharedContactsList].recordList)
        {
            NSString* sectionName   =   @"A";
            if (item.displayName)
            {
                sectionName =   [[NSString stringWithFormat:@"%c",[item.pinyinName characterAtIndex:0] ] uppercaseString];
            }
            NSUInteger firstLetter = [ALPHA rangeOfString:[sectionName substringToIndex:1]].location;
            if (firstLetter != NSNotFound)
                [[self.sectionArray objectAtIndex:firstLetter] addObject:item];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title  =   @"PhoneBook";
    
    if (!self.searchBar) {
        self.searchBar  =   [[[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)] autorelease];
        self.searchBar.delegate =   self;
        self.searchDC   =   [[[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self] autorelease];
        self.searchDC.searchResultsDataSource   =   self;
        self.searchDC.searchResultsDelegate     =   self;
    }
    self.tableView.tableHeaderView  =   self.searchBar;
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:FALSE animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger value;
    if (self.tableView == tableView)
    {
        // 非search结果,第一行为 search bar 按字母分段.
        value   =   26;
    }
    else
    {
        value   =   1;
    }
    return value;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)aTableView
{
	if (aTableView == self.tableView)  // regular table
	{
		NSMutableArray *indices = [NSMutableArray arrayWithObject:UITableViewIndexSearch];
		for (int i = 0; i < 27; i++)
			if ([[self.sectionArray objectAtIndex:i] count])
				[indices addObject:[[ALPHA substringFromIndex:i] substringToIndex:1]];
		//[indices addObject:@"\ue057"]; // <-- using emoji
		return indices;
	}
	else return nil; // search table
}


- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
	if (title == UITableViewIndexSearch)
	{
		[self.tableView scrollRectToVisible:self.searchBar.frame animated:NO];
		return -1;
	}
	return [ALPHA rangeOfString:title].location;
}

- (NSString *)tableView:(UITableView *)aTableView titleForHeaderInSection:(NSInteger)section
{
	if (aTableView == self.tableView)
	{
		if ([[self.sectionArray objectAtIndex:section] count] == 0) return nil;
		return [NSString stringWithFormat:@"%@", [[ALPHA substringFromIndex:section] substringToIndex:1]];
	}
	else return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger value =   0;
    if (self.tableView == tableView)
    {
//        if (section == 0)
//        {
//            value   =   1;
//        }
//        else
        {
            value   =   [(NSMutableArray*)[self.sectionArray objectAtIndex:section /*-1*/] count];
        }
    }
    else
    {
        // search display view
        value   =   [self.searchResult count];
    }
    return value;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *PCellIdentifier = @"phonebookcell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PCellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PCellIdentifier] autorelease];
    }
    if (self.tableView == tableView)
    {
        {
            // Configure the cell...
            ContactsItem* item  =   [[self.sectionArray objectAtIndex:indexPath.section/*-1*/] objectAtIndex:indexPath.row];
            cell.imageView.image    =   item.icon;
            NSMutableString* string =   [[[NSMutableString alloc] init] autorelease];
            if (item.displayName) {
                [string appendString:item.displayName];
            }
            if (item.mobileNumber) {
                [string appendFormat:@" [%@]",item.mobileNumber];
            }
            cell.textLabel.text =   string;
        }
    }
    else
    {
        ContactsItem* item      = [self.searchResult objectAtIndex:[indexPath row]];
        cell.imageView.image    =   item.icon;
        cell.textLabel.text =   item.displayName;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

#pragma mark - UISearchBarDelegate
//- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar;                      // return NO to not become first responder
//- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar;                     // called when text starts editing
//- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar;                        // return NO to not resign first responder
//- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar;                       // called when text ends editing
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText   // called when text changes (including clear)
{
    self.searchResult   =   [self.searchHelper searchResultForKeyword:searchText];
    [self.searchDC.searchResultsTableView reloadData];
}
//- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text NS_AVAILABLE_IOS(3_0); // called before text changes
//
//- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar;                     // called when keyboard search button pressed
//- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar;                   // called when bookmark button pressed
//- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar;                    // called when cancel button pressed
//- (void)searchBarResultsListButtonClicked:(UISearchBar *)searchBar NS_AVAILABLE_IOS(3_2); // called when search results button pressed
//
//- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope NS_AVAILABLE_IOS(3_0);

@end
