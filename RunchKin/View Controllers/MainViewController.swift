//
//  MainViewController.swift
//  RunchKin
//
//  Created by Madison Waters on 3/19/19.
//  Copyright © 2019 Jonah Bergevin. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate{

    // MARK: - Outlets
    @IBOutlet weak var viewBlock: UIView!
    @IBOutlet weak var runButton: UIButton!
    @IBOutlet weak var tableViewController: UITableView!
        
    override func viewDidLoad() {
        super.viewDidLoad()

        viewBlock.layer.addBorder(edge: .top, color: lightGray!, thickness: 10)
        viewBlock.layer.addBorder(edge: .top, color: salmon!, thickness: 5)
        
        viewBlock.backgroundColor = navy
        runButton.backgroundColor = green
        runButton.layer.cornerRadius = runButton.frame.size.width / 2
            
        // Do any additional setup after loading the view.
    }
    
    // MARK: - Fetched Results Controller
    lazy var fetchedResultsController: NSFetchedResultsController<Run> = {
        let fetchRequest: NSFetchRequest<Run> = Run.fetchRequest()
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "timestamp", ascending: false) ]
        
        let moc = CoreDataStack.context //let newRun = Run(context: CoreDataStack.context)
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest,
                                             managedObjectContext: moc,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self
        try? frc.performFetch()
        return frc
    }()
    
    // MARK: - Table View Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MainCell", for: indexPath) as? MainTableViewCell else {
            fatalError("Error dequeueing cell")
        }
        
        let run = fetchedResultsController.object(at: indexPath)
        
        let distance = Measurement(value: run.distance, unit: UnitLength.meters)
        let seconds = Int(run.duration)
        let formattedDate = FormatDisplay.date(run.timestamp)
        let formattedDistance = FormatDisplay.distance(distance)
        let formattedTime = FormatDisplay.time(seconds)
        let formattedPace = FormatDisplay.pace(distance: distance,
                                               seconds: seconds,
                                               outputUnit: UnitSpeed.minutesPerMile)
        
        cell.dateLabel.text = formattedDate
        cell.descriptionLabel.text = "This is the description"
        cell.distanceLabel.text = formattedDistance
        cell.paceLabel.text = formattedPace
        cell.timeLabel.text = formattedTime
        cell.descriptionLabel.text = run.title
        
        let cellImage = UIImage(data: run.image ?? Data())
        cell.runImageView?.image = cellImage
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let run = fetchedResultsController.object(at: indexPath)
            let moc = CoreDataStack.context
            
            moc.delete(run)
            do {
                try moc.save()
            } catch {
                NSLog("Error saving deletion to managed object context: \(error)")
                //moc.reset()
            }
            tableView.reloadData()
            
        }
    }

    
    //MainCell
    
    /*
    // MARK: - Navigation // ShowNewRunVC

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        tableViewController.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
            
        case .insert:
            guard let indexPath = newIndexPath else { return }
            tableViewController.insertRows(at: [indexPath], with: .automatic)
        case .delete:
            guard let indexPath = indexPath else { return }
            tableViewController.deleteRows(at: [indexPath], with: .automatic)
        case .move:
            guard let oldIndexPath = indexPath else { return }
            guard let newIndexPath = newIndexPath else { return }
            tableViewController.moveRow(at: oldIndexPath, to: newIndexPath)
        case .update:
            guard let indexPath = indexPath else { return }
            tableViewController.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        tableViewController.endUpdates()
    }

}
