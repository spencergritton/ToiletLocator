//
//  ViewController.swift
//  Toilet Locator
//
//  Created by Spencer Gritton on 3/9/17.
//  Copyright © 2017 Spencer Gritton. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate{
    
    // Initial calls for useful variables
    // Map Annotation Marker Image
    var manager = CLLocationManager()
    // Businesses for MKLocalSearch Query
    var showTheseBusinesses = ["Gas Stations", "Coffee", "Bathroom", "Fast Food"]
    // Whether or not to focus on user Location
    var locationLock = true
    // Whether activity indicator is on or not
    var activityIndicator = false
    // Timer and counter since last timer
    var timer = Timer()
    var currentTime = 0
    var sinceLastTimer = 0
    
    // If user is searching with search bar?
    var isSearching = false
    
    // Tap to dismiss keyboard
    let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
    
    
    // OUTLETS --
    // Map Declaration
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    // Activity Indicator
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    // Location Lock Outlet
    @IBOutlet weak var LocationLockButtonOutlet: UIButton!
    //Search Bar
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    
    /* VIEW DID APPEAR
 - called everytime the mapView appears, if you go to settings
 then back it will appear again */
    override func viewDidAppear(_ animated: Bool) {
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        mapView.delegate = self
        searchBar.delegate = self
        
        view.addGestureRecognizer(tap)
        
        
        // Swipe Gesture Recognizer
        let swipeRecogonizer = UISwipeGestureRecognizer(target: self, action: #selector(ViewController.generalGestureRecognizer(gesture:)))
        swipeRecogonizer.delegate = self
        // Pan Gesture Recognizer
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ViewController.generalGestureRecognizer(gesture:)))
        panRecognizer.delegate = self
        // Rotate Gesture Recognizer
        let rotationRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(ViewController.generalGestureRecognizer(gesture:)))
        rotationRecognizer.delegate = self
        
        // Add all three gesture recognizers to the mapView
        mapView.addGestureRecognizer(swipeRecogonizer)
        mapView.addGestureRecognizer(panRecognizer)
        mapView.addGestureRecognizer(rotationRecognizer)
        
        // Pre-populate the map after the use location is zoomed in, this happens because the map isn't dragged and
        // the location doesn't move so there will be no pins on the map
        // This only adds "Gas Station" Annotations
        perform(#selector(ViewController.populate(locationQuery:)), with: "Gas Stations", afterDelay: 5)
        activityIndicator = true
        activityIndicatorView.startAnimating()
        tableView.reloadData()
    }
    
    /* LOCATION LOCK BUTTON
     - Locks mapView on and off of user location so you can swipe around */
    @IBAction func LocationLockButtonPressed(_ sender: Any) {
        if locationLock == true {
            
            // if location lock is on and button is pressed turn it to true
            // Also invalidate timer since it is only useful when LL is on
            locationLock = false
            timer.invalidate()
            LocationLockButtonOutlet.setImage(#imageLiteral(resourceName: "LocationObjectOff"), for: .normal)
            
        } else {
            
            // The opposite case, if it's off turn it on
            locationLock = true
            LocationLockButtonOutlet.setImage(#imageLiteral(resourceName: "LocationObject"), for: .normal)
        }
    }
    
    /* GESTURE RECOGNIZER
 - This function allows the mapView to recognize UIGestures outside of it's normal allotted tap and double tap
 - These normally only work on the view controller so this function is key to allowing them to work on the mapView. */
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Check if the gesture is one of the three we are isoltating to use
        if (gestureRecognizer is UIPanGestureRecognizer || gestureRecognizer is UIRotationGestureRecognizer || gestureRecognizer is UISwipeGestureRecognizer) {
            // if so allow the gesture recognizer's specified above to be used
            return true
        } else {
            return false
        }
    }

    
    
    /* GENERAL GESTURE RECOGNIZER
     This is the general gesture recognizer function.
 - If the user is location locked and decides to swipe, rotate, or pan they will be unlocked.
 - This is so that they can move around to look at other toilets and areas easily w/o the location lock button */
    
    func generalGestureRecognizer(gesture: UIGestureRecognizer) {
        if gesture.state == .ended && locationLock == true {
            
            // if someone swipes and location lock is on, turn it off, invalidate timer
            // and change button image
            locationLock = false
            timer.invalidate()
            LocationLockButtonOutlet.setImage(#imageLiteral(resourceName: "LocationObjectOff"), for: .normal)
        }
    }
    
    
    /* MAP VIEW
 - Basically controls how certain annotations are shown, their callouts, images etc.. */
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? LocationObjects{
            if let view = mapView.dequeueReusableAnnotationView(withIdentifier: annotation.identifier){
                return view
            }else{
                
                let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotation.identifier)
                
                view.isEnabled = true
                view.canShowCallout = true
                
                // Setting map pin to appropriate icon
                if annotation.identifier == "Gas Stations" {
                    view.image = #imageLiteral(resourceName: "GasMapIcon")
                } else if annotation.identifier == "Coffee" {
                    view.image = #imageLiteral(resourceName: "CoffeeMapIcon")
                } else if annotation.identifier == "Fast Food" {
                    view.image = #imageLiteral(resourceName: "FoodMapIcon")
                } else {
                    view.image = #imageLiteral(resourceName: "ToiletMapIcon")
                }
                
                // Right Accessory View
                
                let placemark = MKPlacemark(coordinate: CLLocationCoordinate2DMake(annotation.coordinate.latitude, annotation.coordinate.longitude), addressDictionary: nil)
                
                let button = CalloutButton(name: annotation.title!, placemark: placemark)
                //button.frame = (frame: CGRect(x: 0, y: 0, width: 70, height: 30))
                button.frame = CGRect(x: 0, y: 0, width: 70, height: 30)
                button.backgroundColor = UIColor.clear
                button.setTitle("Open in Maps", for: .normal)
                button.titleLabel?.font = UIFont(name: "Verdana", size: 10)
                button.setTitleColor(UIColor.blue, for: .normal)

                
                button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
                view.rightCalloutAccessoryView = button
                
                // Detail Accessory View
                var image = #imageLiteral(resourceName: "ToiletMapIcon-1")
                
                if annotation.identifier == "Gas Stations" {
                    image = #imageLiteral(resourceName: "GasMapIcon-1")
                } else if annotation.identifier == "Coffee" {
                    image = #imageLiteral(resourceName: "CoffeeMapIcon-1")
                } else if annotation.identifier == "Fast Food" {
                    image = #imageLiteral(resourceName: "FoodMapIcon-1")
                }

                view.detailCalloutAccessoryView = UIImageView(image: image)
                
                // Empty left label until info can be added
                let label = UILabel(frame: CGRect(x: 0,y: 0,width: 50,height: 30))
                label.text = ""
                label.adjustsFontSizeToFitWidth = true
                view.leftCalloutAccessoryView = label
                
                return view
            }
        }
        return nil
    }
    
    /* DIDSELECT
 - sets up left view detailing how long a route would take to drive
 - Requests an ETA then returns it in label */
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let userLocation = CLLocation(latitude: mapView.userLocation.coordinate.latitude, longitude: mapView.userLocation.coordinate.longitude)
        let destinationLocation = CLLocationCoordinate2DMake((view.annotation?.coordinate.latitude)!, (view.annotation?.coordinate.longitude)!)
        
        let leftAccessory = UILabel(frame: CGRect(x: 0,y: 0,width: 80,height: 30))
        leftAccessory.font = UIFont(name: "Verdana", size: 10)
        
        requestETA(userCLLocation: userLocation, coordinate: destinationLocation) { (travelTime, error) in
            guard var travelTime = travelTime, error == nil else { return }
            
            let travelTimeDouble = Double(travelTime)

            travelTime = String(format: "%.0f", travelTimeDouble!)
            leftAccessory.text = travelTime + " Minute Drive"
            view.leftCalloutAccessoryView = leftAccessory
        }
        
    }
    
    /* REQUESTETA
 - The absolute worst function to write, probably took a week of Googling efforts.
 - Calls Apple's maps API to requst the length of time one a round from point A -> B would take */
    func requestETA(userCLLocation: CLLocation, coordinate: CLLocationCoordinate2D, completion: @escaping (_ string: String?, _ error: Error?) -> () ) {
        
        let request = MKDirectionsRequest()
        /* Source MKMapItem */
        let sourceItem = MKMapItem(placemark: MKPlacemark(coordinate: userCLLocation.coordinate, addressDictionary: nil))
        request.source = sourceItem
        /* Destination MKMapItem */
        let destinationItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
        request.destination = destinationItem
        request.requestsAlternateRoutes = false
        // Looking for walking directions
        request.transportType = MKDirectionsTransportType.automobile
        
        // You use the MKDirectionsRequest object constructed above to initialise an MKDirections object
        let directions = MKDirections(request: request)
        
        var travelTime = "Not Available"
        
            directions.calculate { response, error in
                if let route = response?.routes.first {
                    travelTime = "\(route.expectedTravelTime/60)"
                }
                completion(travelTime, error)
            }
    }
    
    
    // Button function that takes users to open the route to a location on maps, called from MAP VIEW
    func buttonAction(sender: CalloutButton!) {
        
        let mapItem = MKMapItem(placemark: sender.internalPlacemark)
        mapItem.name = sender.internalName
        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeTransit]
        mapItem.openInMaps(launchOptions: launchOptions)
        
    }
    
    
    /* DIDUPDATELOCATIONS
 - Extremely important, called anytime the users location is updated assuming locationLock is on */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Check if location lock is on, if not leave request
        if locationLock == false{
            return
        }
        
        // If the timer is not running then start it
        if timer.isValid == false {
            // Reset current and sinceLast counters
            currentTime = 0
            sinceLastTimer = 0
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.timeCounter), userInfo: nil, repeats: true)
        }
        
        // This function sets map to users location every time it updates
        let location = locations[0]
        let span: MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01)
        
        let myLocations: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        
        let region:MKCoordinateRegion = MKCoordinateRegionMake(myLocations, span)
        mapView.setRegion(region, animated: true)
        // Show the user location on the map
        self.mapView.showsUserLocation = true
        
        // For each item in the showTheseBusinesses array create a MKLocalSearch Query using that item as the query (populate function)
        // This is only called every five seconds with the assistance of a Timer
        
        if (currentTime - sinceLastTimer) > 5 {
            // if they are greater than five then set them equal to keep counting five seconds
            sinceLastTimer = currentTime
            
            for item in showTheseBusinesses {
                populate(locationQuery: item)
            }
            tableView.reloadData()
            
        }
    }
    
    
    /* REGIONWILLCHANGE
 - This is if the user is swiping on the screen or rotating the map
 - Basically if they are scrolling away from their location to check out somewhere else this will
    populate the region with businesses */
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        // Check if location lock is off, if not don't do anything
        if locationLock == true {
            return
        }
        // if location lock is off then user is scrolling and wants to see businesses away 
        // from their personal location
        
        // For each item in the showTheseBusinesses array create a MKLocalSearch Query using that item as the query
        // This is done through the populate function.. could use a better name.
       
        for item in showTheseBusinesses {
            populate(locationQuery: item)
        }
        tableView.reloadData()
    }
    /* REGIONDIDCHANGE */
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Check if location lock is off, if not don't do anything
        if locationLock == true {
            return
        }
        // if location lock is off then user is scrolling and wants to see businesses away
        // from their personal location
        
        // For each item in the showTheseBusinesses array create a MKLocalSearch Query using that item as the query
        // This is done through the populate function.. could use a better name.
        for item in showTheseBusinesses {
            populate(locationQuery: item)
        }
        tableView.reloadData()
    }
    // ---------------------------------------- RegionDidChange and RegionWillChange do the same thing
    
    
    // Useful arrays for handling placing annotations on the map and avoiding double placing annotations
    var prePopulated = [LocationObjects]()
    var toPopulate = [LocationObjects]()
    
    // For filtering with search bar
    var filteredPopulated = [LocationObjects]()
    
    
    /* POPULATE
     - The brain-child of the entire operation. This creates MKLocalSearch Queries for one item at a time.
     it then checks if the map has the local businesses on the map and if not adds them. */
    func populate(locationQuery: String) {
        
        // Check if list is empty in which case activity indicator should be on
        if (prePopulated.isEmpty == true) && (activityIndicator == false) {
            
            activityIndicator = true
            activityIndicatorView.startAnimating()
            
        }
        
        // Set region to search for
        var region = MKCoordinateRegion()
        region.center = CLLocationCoordinate2D(latitude: self.mapView.centerCoordinate.latitude, longitude: self.mapView.centerCoordinate.longitude)
        
        //Requesting search for businesses in region
        let request = MKLocalSearchRequest()
        //Requesting by business type
        request.naturalLanguageQuery = locationQuery
        request.region = region
        
        
        //Search for region
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            
            // Only allow responses with business information
            guard response != nil else {
                return
            }
            
            // For each allowed item create a custom LocationObjects object using the data
            mainLoop: for item in (response?.mapItems)! {
                
                //self.perform(#selector(ViewController.buildLocationObject(item:)), with: item, afterDelay: 0.2)
                self.buildLocationObject(item: item, locationQuery: locationQuery)
                
                
            }
        }
        
        // Add annotations to map that are nearby and not already on the map
        sortPrePopulated()
        addAnnotations()
        
        // Delete old and annotations more than ten miles away to conserve space
        deleteLocationsTenMilesAway()
    }
    
    /* BUILDLOCATIONOBJECT
 - Called directly above, builds necessary LocationObjects for placement in map and in array.*/
    func buildLocationObject(item: MKMapItem, locationQuery: String) {
        
        // Finding phone number if available
        var phone:String
        if item.phoneNumber != nil {
            phone = item.phoneNumber!
        } else {
            phone = ""
        }
        
        // Finding name if available
        var name:String
        if item.name != nil {
            name = item.name!
        } else {
            name = ""
        }
        
        // Finding address if available
        var address:String
        if (item.placemark.subThoroughfare != nil) {
            address = item.placemark.subThoroughfare! + " " + item.placemark.thoroughfare! + " " + item.placemark.locality! + ", " + item.placemark.administrativeArea! + " " + item.placemark.postalCode!
        } else {
            address = ""
        }
        
        let annotation = LocationObjects(name: name, lat: item.placemark.coordinate.latitude, long: item.placemark.coordinate.longitude, userCLLocation: CLLocation(latitude: self.mapView.userLocation.coordinate.latitude, longitude: self.mapView.userLocation.coordinate.longitude), phone: phone, address: address, locationType: locationQuery)
        
        // if the annotation is already on the map skip it
        if self.prePopulated.contains(annotation) {
            return
            
        } else {
            // else not on map already and append it to the toPopulate to deal with later on
            self.toPopulate.append(annotation)
        }
        
    }
    
    
    
    /* DELETELOCATIONSTENMILESAWAY
 - New function that is very useful on reducing clutter.
 - Makes sure that if an annotation is not within ten miles of the users view that it is deleted to keep the app running freshly and without problems. This is done by calculating distance between the center of the map and all annotations on
     the map. */
    func deleteLocationsTenMilesAway() {
        //If an annotation is in the map but is not nearby.. Delete it
        for annotation in mapView.annotations {
            if (annotation is MKUserLocation) {
                continue
            } else {
                // Set userView to the Center mapView coords and annotationPoint to each annotation and check distance
                // between the two
                let userView = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
                let annotationPoint = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
                let distance = userView.distance(from: annotationPoint)
                
                // Check how far away annotation is from user view, if over 10 miles (in meters) then delete annotation
                if distance > 16093 {
                    mapView.removeAnnotation(annotation)
                    prePopulated = prePopulated.filter() { $0 !== annotation }
                } else {
                    continue
                }
            }
        }
        
        // Extra check to make sure no annotations in the mapView or table have Distance > 10 Mi
        for annotation in prePopulated {
            if annotation.distance > 10 {
                mapView.removeAnnotation(annotation)
                prePopulated = prePopulated.filter() { $0 !== annotation }
            }
        }
        
        // turn activity indicator off if it is on when we know there are things in the map
        if (activityIndicator == true) && (prePopulated.isEmpty == false) {
            activityIndicator = false
            activityIndicatorView.stopAnimating()
            activityIndicatorView.hidesWhenStopped = true
        }
    }
    
    /* ADDANNOTATIONS
 - Function that adds annotations from the toPopulate que to the map, if not already on map
 - Then removes from the que and adds to the prePopulated AKA already on map list. */
    func addAnnotations() {
        mainAddLoop: for annotation in toPopulate {
            // If it's already on the map (prePopulated) move on
            // check if similar placed annotation is already on map
            for currentAnnotation in prePopulated {
                if currentAnnotation.coordinate.latitude == annotation.coordinate.latitude {
                    
                    toPopulate = toPopulate.filter() { $0 !== annotation }
                    continue mainAddLoop
                    
                }
            }
            
            if prePopulated.contains(annotation) {
                toPopulate = toPopulate.filter() { $0 !== annotation }
                continue mainAddLoop
                
            } else {
                // The annotation is not already on the map and needs to be added
                prePopulated.append(annotation)
                mapView.addAnnotation(annotation)
                toPopulate = toPopulate.filter() { $0 !== annotation }
            }
        }
    }
    
    
    /* SORTPREPOPULATED
 - Sorts prePopulated list in order of ascending distance */
    func sortPrePopulated() {
        prePopulated = prePopulated.sorted(by: { $0.distance < $1.distance } )
    }
    
    /* OPENANNOTATION
 - Thanks to stackoverflow.com/questions/2193843/how-to-open-call-out-mkannotatioview-programmatically-iphone-mapkit
 - Opens callout view of annotation passed into it */
    func openAnnotation(id: MKAnnotation) {
        _ = [mapView .selectAnnotation(id, animated: true)]
    }
    
    /* TIMECOUNTER
 - adds one to current time when called */
    func timeCounter() {
        currentTime += 1
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchBar.text == nil || searchBar.text == "" {
            
            isSearching = false
            
            filteredPopulated = [LocationObjects]()
            
            view.endEditing(true)
            
            tableView.reloadData()
            
        } else {
            
            isSearching = true
            
            filteredPopulated = [LocationObjects]()
            
            for locationObject in prePopulated {
                
                let title = locationObject.title?.lowercased()
                let search = searchBar.text?.lowercased()
                
                if (title?.contains(search!))! {
                    
                    if filteredPopulated.contains(locationObject) {
                        continue
                    } else {
                        
                    filteredPopulated.append(locationObject)
                        
                    }
                    
                }
            }
            
            tableView.reloadData()
            
        }
        
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        view.endEditing(true)
        
    }
    
    func dismissKeyboard() {
        
        if isSearching == true {
            view.endEditing(true)
        }
        
    }
    
    
    // START TABLE VIEW FUNCTIONS ------------------------------------------------------------------
    
    /* NUMBEROFROWSINSECTION
 - returns the number of rows in prePopulated, making the table as long as the array */
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if isSearching {
            return filteredPopulated.count
        }
        
        return prePopulated.count
    }
    
    /* CELLFORROWAT
 - Customizes what each cell contains: text, images, etc.. */
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Tells the table to use the cell "Cell"
        let cell = Bundle.main.loadNibNamed("TableViewCell1", owner: self, options: nil)?.first as! TableViewCell1
        
        // IF THE USER IS SEARCHING
        
        if isSearching {
            
            // Set Title
            if filteredPopulated[indexPath.row].title != "" {
                
                cell.TitleLabel.text = filteredPopulated[indexPath.row].title
            } else {
                cell.TitleLabel.text = "Not Availabile"
            }
            
            // Set Address
            if filteredPopulated[indexPath.row].addressFinished != "" {
                
                cell.AddressLabel.text = filteredPopulated[indexPath.row].addressFinished
            } else {
                cell.AddressLabel.text = "Not Availabile"
            }
            
            // Set Phone
            if filteredPopulated[indexPath.row].phoneNumber != "" {
                
                cell.PhoneLabel.text = filteredPopulated[indexPath.row].phoneNumber
            } else {
                cell.PhoneLabel.text = "Not Availabile"
            }
            
            // Set Distance
            cell.DistanceLabel.text = String(filteredPopulated[indexPath.row].distance) + "mi."
            
            return cell

            
        }
        
        // IF USER NOT SEARCHING
        
        // Set Title
        if prePopulated[indexPath.row].title != "" {
            
            cell.TitleLabel.text = prePopulated[indexPath.row].title
        } else {
            cell.TitleLabel.text = "Not Availabile"
        }
        
        // Set Address
        if prePopulated[indexPath.row].addressFinished != "" {
            
            cell.AddressLabel.text = prePopulated[indexPath.row].addressFinished
        } else {
            cell.AddressLabel.text = "Not Availabile"
        }
        
        // Set Phone
        if prePopulated[indexPath.row].phoneNumber != "" {
            
            cell.PhoneLabel.text = prePopulated[indexPath.row].phoneNumber
        } else {
            cell.PhoneLabel.text = "Not Availabile"
        }
        
        // Set Distance
            cell.DistanceLabel.text = String(prePopulated[indexPath.row].distance) + "mi."
        
        return cell
    }
    
    /* DIDSELECTROWAT
 - What happens when the user clicks one of the cells in the table */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Turn location lock off, zoom map to the coordinates of the place selected.
        locationLock = false
        LocationLockButtonOutlet.setImage(#imageLiteral(resourceName: "LocationObjectOff"), for: .normal)
        
        let region = MKCoordinateRegionMakeWithDistance(prePopulated[indexPath.row].coordinate, 500, 500)
        mapView.setRegion(region, animated: true)
        
        // Open the annotation callout view on the map
        openAnnotation(id: prePopulated[indexPath.row])
        
    }
    
    // For some reason this function works but not the above.. more tests needed
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        // Turn location lock off, zoom map to the coordinates of the place selected.
        locationLock = false
        LocationLockButtonOutlet.setImage(#imageLiteral(resourceName: "LocationObjectOff"), for: .normal)
        
        let region = MKCoordinateRegionMakeWithDistance(prePopulated[indexPath.row].coordinate, 500, 500)
        mapView.setRegion(region, animated: true)
        
        // Open the annotation callout view on the map
        openAnnotation(id: prePopulated[indexPath.row])
    }
}






