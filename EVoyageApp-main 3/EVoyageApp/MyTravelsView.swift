//
//  MapView.swift
//  EVoyageApp
//
//  Created by Furkan Erdoğan on 26.05.2024.
//

//import SwiftUI
//import Firebase
//
//struct MyTravelsView: View {
//    private let db = Firestore.firestore()
//    
//    @State var travels: [TravelDBModel] = []
//    
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                Color.blue.ignoresSafeArea()
//                VStack {
//                    ScrollView {
//                        LazyVStack {
//                            ForEach(travels, id: \.id) { travel in
//                                FlightSelectionRowView(travel: travel) {
//                                    
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//            .navigationTitle("My Trip")
//            .task {
//                do {
//                    guard let user = try? await CurrentUserInfoService.shared.getCurrentUser() else { return }
//                    let travels = try await fetchTravels(for: user)
//                    self.travels = travels
//                } catch {
//                    print("Hata var: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//    
//    private func fetchTravels(for currentUser: UserDB) async throws -> [TravelDBModel] {
//        let excludedUserUids = [currentUser.userUid]
//        return try await db.collection("Travels")
//            .whereField("user.uid", in: excludedUserUids)
//            .getDocuments()
//            .documents
//            .compactMap { try? $0.data(as: TravelDBModel.self) }
//            .sorted { $0.publishedDate > $1.publishedDate }
//    }
//}
//
//#Preview {
//    MyTravelsView()
//}
//
//struct FlightSelectionRowView: View {
//    let travel: TravelDBModel
//    let tapped: () -> Void
//    
//    var body: some View {
//        Button {
//            tapped()
//        } label: {
//            VStack(alignment: .leading, spacing: 8) {
//                
//                HStack {
//                    Text(travel.departure.province)
//                    Image(systemName: "arrow.forward")
//                    Text(travel.arrival.province)
//                    Spacer()
//                    Text(travel.departureDate.formattedAsDDMMYYYY)
//                        .font(
//                            .system(
//                                size: 16,
//                                weight: .regular,
//                                design: .rounded
//                            )
//                        )
//                        .foregroundStyle(Color.white)
//                }
//                .font(
//                    .system(
//                        size: 16,
//                        weight: .semibold,
//                        design: .rounded
//                    )
//                )
//                .foregroundStyle(Color.white)
//                
//                HStack(spacing: 16) {
//                    
//                }
//                .font(
//                    .system(
//                        size: 14,
//                        weight: .regular,
//                        design: .rounded
//                    )
//                )
//                .foregroundStyle(Color.white)
//            }
//            .frame(maxWidth: .infinity)
//            .padding(.vertical, 10)
//            .safeAreaInset(edge: .bottom) {
//                Color.red
//                    .frame(height: 0.4)
//            }
//            .padding(.horizontal, 16)
//        }
//    }
//}

import SwiftUI
import MapKit
import SwiftData

struct TripMapView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var visibleRegion: MKCoordinateRegion?
    @Environment(LocationManager.self) var locationManager
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @Query private var listPlacemarks: [MTPlacemark]
    
    // Search
    @State private var searchText = ""
    @FocusState private var searchFieldFocus: Bool
    @Query(filter: #Predicate<MTPlacemark> {$0.destination == nil}) private var searchPlacemarks: [MTPlacemark]
    
    @State private var selectedPlacemark: MTPlacemark?
    
    // Route
    @State private var showRoute = false
    @State private var routeDisplaying = false
    @State private var route: MKRoute?
    @State private var routeDestination: MKMapItem?
    @State private var travelInterval: TimeInterval?
    @State private var transportType = MKDirectionsTransportType.automobile
    @State private var showSteps = false
    @Namespace private var mapScope
    @State private var mapStyleConfig = MapStyleConfig()
    @State private var pickMapStyle = false
    
    var body: some View {
        Map(position: $cameraPosition, selection: $selectedPlacemark, scope: mapScope) {
            UserAnnotation()
            ForEach(listPlacemarks) { placemark in
                if !showRoute {
                    Group {
                        if placemark.destination != nil {
                            Marker(coordinate: placemark.coordinate) {
                                Label(placemark.name, systemImage: "star")
                            }
                            .tint(.yellow)
                        } else {
                            Marker(placemark.name, coordinate: placemark.coordinate)
                        }
                    }.tag(placemark)
                } else {
                    if let routeDestination {
                        Marker(item: routeDestination)
                            .tint(.green)
                    }
                }
            }
            if let route, routeDisplaying {
                MapPolyline(route.polyline)
                    .stroke(.blue, lineWidth: 6)
            }
        }
        .sheet(item: $selectedPlacemark) { selectedPlacemark in
            LocationDetailView(
                selectedPlacemark: selectedPlacemark,
                showRoute: $showRoute,
                travelInterval: $travelInterval,
                transportType: $transportType
            )
                .presentationDetents([.height(450)])
        }
        .onMapCameraChange{ context in
            visibleRegion = context.region
        }
        .onAppear {
            MapManager.removeSearchResults(modelContext)
            updateCameraPosition()
        }
        .mapControls{
            MapScaleView()
        }
        .mapStyle(mapStyleConfig.mapStyle)
        .task(id: selectedPlacemark) {
            if selectedPlacemark != nil {
                routeDisplaying = false
                showRoute = false
                route = nil
                await fetchRoute()
            }
        }
        .onChange(of: showRoute) {
            selectedPlacemark = nil
            if showRoute {
                withAnimation {
                    routeDisplaying = true
                    if let rect = route?.polyline.boundingMapRect {
                        cameraPosition = .rect(rect)
                    }
                }
            }
        }
        .task(id: transportType) {
            await fetchRoute()
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                VStack {
                    TextField("Search...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($searchFieldFocus)
                        .overlay(alignment: .trailing) {
                            if searchFieldFocus {
                                Button {
                                    searchText = ""
                                    searchFieldFocus = false
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .offset(x: -5)
                            }
                        }
                        .onSubmit {
                            Task {
                                await MapManager.searchPlaces(
                                    modelContext,
                                    searchText: searchText,
                                    visibleRegion: visibleRegion
                                )
                                searchText = ""
                            }
                        }
                    if routeDisplaying {
                        HStack {
                            Button("Clear Route", systemImage: "xmark.circle") {
                                removeRoute()
                            }
                            .buttonStyle(.borderedProminent)
                            .fixedSize(horizontal: true, vertical: false)
                            Button("Show Steps", systemImage: "location.north") {
                                showSteps.toggle()
                            }
                            .buttonStyle(.borderedProminent)
                            .fixedSize(horizontal: true, vertical: false)
                            .sheet(isPresented: $showSteps) {
                                if let route {
                                    NavigationStack {
                                        List {
                                            HStack {
                                                Image(systemName: "mappin.circle.fill")
                                                    .foregroundStyle(.red)
                                                Text("From my location")
                                                Spacer()
                                            }
                                            ForEach(1..<route.steps.count, id: \.self) { idx in
                                                VStack(alignment: .leading) {
                                                    Text("\(transportType == .automobile ? "Drive" : "Walk") \(MapManager.distance(meters: route.steps[idx].distance))")
                                                        .bold()
                                                    Text(" - \(route.steps[idx].instructions)")
                                                }
                                            }
                                        }
                                        .listStyle(.plain)
                                        .navigationTitle("Steps")
                                        .navigationBarTitleDisplayMode(.inline)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                VStack {
                    if !searchPlacemarks.isEmpty {
                        Button {
                            MapManager.removeSearchResults(modelContext)
                        } label: {
                            Image(systemName: "mappin.slash")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                    Button {
                        pickMapStyle.toggle()
                    } label: {
                        Image(systemName: "globe.americas.fill")
                            .imageScale(.large)
                    }
                    .padding(8)
                    .background(.thickMaterial)
                    .clipShape(.circle)
                    .sheet(isPresented: $pickMapStyle) {
                        MapStyleView(mapStyleConfig: $mapStyleConfig)
                            .presentationDetents([.height(275)])
                    }
                    MapUserLocationButton(scope: mapScope)
                    MapCompass(scope: mapScope)
                        .mapControlVisibility(.visible)
                    MapPitchToggle(scope: mapScope)
                        .mapControlVisibility(.visible)
                }
                .padding()
                .buttonBorderShape(.circle)
            }
        }
        .mapScope(mapScope)
    }
    
    func updateCameraPosition() {
        if let userLocation = locationManager.userLocation {
            let userRegion = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.15,
                    longitudeDelta: 0.15
                )
            )
            withAnimation {
                cameraPosition = .region(userRegion)
            }
        }
    }
    
    func fetchRoute() async {
        if let userLocation = locationManager.userLocation, let selectedPlacemark {
            let request = MKDirections.Request()
            let sourcePlacemark = MKPlacemark(coordinate: userLocation.coordinate)
            let routeSource = MKMapItem(placemark: sourcePlacemark)
            let destinatinPlacemark = MKPlacemark(coordinate: selectedPlacemark.coordinate)
            routeDestination = MKMapItem(placemark: destinatinPlacemark)
            routeDestination?.name = selectedPlacemark.name
            request.source = routeSource
            request.destination = routeDestination
            request.transportType = transportType
            let directions = MKDirections(request: request)
            let result = try? await directions.calculate()
            route = result?.routes.first
            travelInterval = route?.expectedTravelTime
        }
    }
    
    func removeRoute() {
        routeDisplaying = false
        showRoute = false
        route = nil
        selectedPlacemark = nil
        updateCameraPosition()
    }
}

#Preview {
    TripMapView()
        .environment(LocationManager())
        .modelContainer(Destination.preview)
}

import SwiftData
import MapKit

@Model
class MTPlacemark {
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var destination: Destination?
    
    init(name: String, address: String, latitude: Double, longitude: Double) {
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
    }
    
    var coordinate: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }
}


import SwiftUI
import CoreLocation

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
  @ObservationIgnored let manager = CLLocationManager()
    var userLocation: CLLocation?
    var isAuthorized = false
    
    override init() {
        super.init()
        manager.delegate = self
        startLocationServices()
    }
    
    func startLocationServices() {
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
            isAuthorized = true
        } else {
            isAuthorized = false
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            isAuthorized = true
            manager.requestLocation()
        case .notDetermined:
            isAuthorized = false
            manager.requestWhenInUseAuthorization()
        case .denied:
            isAuthorized = false
            print("access denied")
        default:
            isAuthorized = true
            startLocationServices()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

import MapKit
import SwiftData

enum MapManager {
    @MainActor
    static func searchPlaces(_ modelContext: ModelContext, searchText: String, visibleRegion: MKCoordinateRegion?) async {
        removeSearchResults(modelContext)
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        if let visibleRegion {
            request.region = visibleRegion
        }
        let searchItems = try? await MKLocalSearch(request: request).start()
        let results = searchItems?.mapItems ?? []
        results.forEach {
            let mtPlacemark = MTPlacemark(
                name: $0.placemark.name ?? "",
                address: $0.placemark.title ?? "",
                latitude: $0.placemark.coordinate.latitude,
                longitude: $0.placemark.coordinate.longitude
            )
            modelContext.insert(mtPlacemark)
        }
    }
    
    static func removeSearchResults(_ modelContext: ModelContext) {
        let searchPredicate = #Predicate<MTPlacemark> { $0.destination == nil }
        try? modelContext.delete(model: MTPlacemark.self, where: searchPredicate)
    }

    static func distance(meters: Double) -> String {
        let userLocale = Locale.current
        let formatter = MeasurementFormatter()
        var options: MeasurementFormatter.UnitOptions = []
        options.insert(.providedUnit)
        options.insert(.naturalScale)
        formatter.unitOptions = options
        let meterValue = Measurement(value: meters, unit: UnitLength.meters)
        let yardsValue = Measurement(value: meters, unit: UnitLength.yards)
        return formatter.string(from: userLocale.measurementSystem == .metric ? meterValue : yardsValue)
    }
}

import SwiftData
import MapKit

@Model
class Destination {
    var name: String
    var latitude: Double?
    var longitude: Double?
    var latitudeDelta: Double?
    var longitudeDelta: Double?
    @Relationship(deleteRule: .cascade)
    var placemarks: [MTPlacemark] = []
    
    init(name: String, latitude: Double? = nil, longitude: Double? = nil, latitudeDelta: Double? = nil, longitudeDelta: Double? = nil) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.latitudeDelta = latitudeDelta
        self.longitudeDelta = longitudeDelta
    }
    
    var region: MKCoordinateRegion? {
        if let latitude, let longitude, let latitudeDelta, let longitudeDelta {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            )
        } else {
            return nil
        }
    }
}

extension Destination {
    @MainActor
    static var preview: ModelContainer {
        let container = try! ModelContainer(
            for: Destination.self,
            configurations: ModelConfiguration(
                isStoredInMemoryOnly: true
            )
        )
//        let paris = CLLocationCoordinate2D(latitude: 48.856788, longitude: 2.351077)
//        let parisSpan = MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        let paris = Destination(
            name: "Paris",
            latitude: 48.856788,
            longitude: 2.351077,
            latitudeDelta: 0.15,
            longitudeDelta: 0.15
        )
        container.mainContext.insert(paris)
        var placeMarks: [MTPlacemark] {
            [
                MTPlacemark(name: "Louvre Museum", address: "93 Rue de Rivoli, 75001 Paris, France", latitude: 48.861950, longitude: 2.336902),
                MTPlacemark(name: "Sacré-Coeur Basilica", address: "Parvis du Sacré-Cœur, 75018 Paris, France", latitude: 48.886634, longitude: 2.343048),
                MTPlacemark(name: "Eiffel Tower", address: "5 Avenue Anatole France, 75007 Paris, France", latitude: 48.858258, longitude: 2.294488),
                MTPlacemark(name: "Moulin Rouge", address: "82 Boulevard de Clichy, 75018 Paris, France", latitude: 48.884134, longitude: 2.332196),
                MTPlacemark(name: "Arc de Triomphe", address: "Place Charles de Gaulle, 75017 Paris, France", latitude: 48.873776, longitude: 2.295043),
                MTPlacemark(name: "Gare Du Nord", address: "Paris, France", latitude: 48.880071, longitude: 2.354977),
                MTPlacemark(name: "Notre Dame Cathedral", address: "6 Rue du Cloître Notre-Dame, 75004 Paris, France", latitude: 48.852972, longitude: 2.350004),
                MTPlacemark(name: "Panthéon", address: "Place du Panthéon, 75005 Paris, France", latitude: 48.845616, longitude: 2.345996),
            ]
        }
        placeMarks.forEach {placemark in
            paris.placemarks.append(placemark)
        }
        return container
    }
}

import SwiftUI

struct MapStyleView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var mapStyleConfig: MapStyleConfig
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                LabeledContent("Base Style") {
                    Picker("Base Style", selection: $mapStyleConfig.baseStyle) {
                        ForEach(MapStyleConfig.BaseMapStyle.allCases, id: \.self) { type in
                            Text(type.label)
                        }
                    }
                }
                LabeledContent("Elevation") {
                    Picker("Elevation", selection: $mapStyleConfig.elevation) {
                        Text("Flat").tag(MapStyleConfig.MapElevation.flat)
                        Text("Realistic").tag(MapStyleConfig.MapElevation.realistic)
                    }
                }
                if mapStyleConfig.baseStyle != .imagery {
                    LabeledContent("Points of Interest") {
                        Picker("Points of Interest", selection: $mapStyleConfig.pointsOfInterest) {
                            Text("None").tag(MapStyleConfig.MapPOI.excludingAll)
                            Text("All").tag(MapStyleConfig.MapPOI.all)
                            Text("EVCharger").tag(MapStyleConfig.MapPOI.evCharger)
                        }
                    }
                    Toggle("Show Traffic", isOn: $mapStyleConfig.showTraffic)
                }
                Button("OK") {
                    dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Map Style")
            .navigationBarTitleDisplayMode(.inline)
            Spacer()
        }
    }
}


#Preview {
    MapStyleView(mapStyleConfig: .constant(MapStyleConfig.init()))
}

import SwiftUI
import MapKit

struct MapStyleConfig {
    enum BaseMapStyle: CaseIterable {
        case standard, hybrid, imagery
        var label: String {
            switch self {
            case .standard:
                "Standard"
            case .hybrid:
                "Satellite with roads"
            case .imagery:
                "Satellite only"
            }
        }
    }
    
    enum MapElevation {
        case flat, realistic
        var selection: MapStyle.Elevation {
            switch self {
            case .flat:
                    .flat
            case .realistic:
                    .realistic
            }
        }
    }
    
    enum MapPOI {
        case all, excludingAll, evCharger
        var selection: PointOfInterestCategories {
            switch self {
            case .all:
                    .all
            case .excludingAll:
                    .excludingAll
            case .evCharger:
                PointOfInterestCategories.including(.evCharger)
            }
        }
    }
    
    var baseStyle = BaseMapStyle.standard
    var elevation = MapElevation.flat
    var pointsOfInterest = MapPOI.excludingAll
    
    var showTraffic = false
    
    var mapStyle: MapStyle {
        switch baseStyle {
        case .standard:
            MapStyle.standard(elevation: elevation.selection, pointsOfInterest: pointsOfInterest.selection, showsTraffic: showTraffic)
        case .hybrid:
            MapStyle.hybrid(elevation: elevation.selection, pointsOfInterest: pointsOfInterest.selection, showsTraffic: showTraffic)
        case .imagery:
            MapStyle.imagery(elevation: elevation.selection)
        }
    }
}

import SwiftUI
import MapKit
import SwiftData

struct LocationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    var destination: Destination?
    var selectedPlacemark: MTPlacemark?
    @Binding var showRoute: Bool
    @Binding var travelInterval: TimeInterval?
    @Binding var transportType: MKDirectionsTransportType
    
    var travelTime: String? {
        guard let travelInterval else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: travelInterval)
    }
    
    @State private var name = ""
    @State private var address = ""
    
    @State private var lookaroundScene: MKLookAroundScene?
    
    var isChanged: Bool {
        guard let selectedPlacemark else { return false }
        return (name != selectedPlacemark.name || address != selectedPlacemark.address)
    }
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    if destination != nil {
                        TextField("Name", text: $name)
                            .font(.title)
                        TextField("address", text: $address, axis: .vertical)
                        if isChanged {
                            Button("Update") {
                                selectedPlacemark?.name = name
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                selectedPlacemark?.address = address
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        Text(selectedPlacemark?.name ?? "")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(selectedPlacemark?.address ?? "")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.trailing)
                    }
                    if destination == nil {
                        HStack {
                            Button {
                                transportType = .automobile
                            }label: {
                                Image(systemName: "car")
                                    .symbolVariant(transportType == .automobile ? .circle : .none)
                                    .imageScale(.large)
                            }
                            Button {
                                transportType = .walking
                            }label: {
                                Image(systemName: "figure.walk")
                                    .symbolVariant(transportType == .walking ? .circle : .none)
                                    .imageScale(.large)
                            }
                            if let travelTime {
                                let prefix = transportType == .automobile ? "Driving" : "Walking"
                                Text("\(prefix) time: \(travelTime)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                Spacer()
                Button {
                   dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.large)
                        .foregroundStyle(.gray)
                }
            }
            if let lookaroundScene {
                LookAroundPreview(initialScene: lookaroundScene)
                    .frame(height: 200)
                    .padding()
            } else {
                ContentUnavailableView("No preview available", systemImage: "eye.slash")
            }
            HStack {
                Spacer()
                if let destination {
                    let inList = (selectedPlacemark != nil && selectedPlacemark?.destination != nil)
                    Button {
                        if let selectedPlacemark {
                            if selectedPlacemark.destination == nil {
                                destination.placemarks.append(selectedPlacemark)
                            } else {
                                selectedPlacemark.destination = nil
                            }
                            dismiss()
                        }
                    } label: {
                        Label(inList ? "Remove" : "Add", systemImage: inList ? "minus.circle" : "plus.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(inList ? .red : .green)
                    .disabled((name.isEmpty || isChanged))
                } else {
                    HStack {
                        Button("Open in maps", systemImage: "map") {
                            if let selectedPlacemark {
                                let placemark = MKPlacemark(coordinate: selectedPlacemark.coordinate)
                                let mapItem = MKMapItem(placemark: placemark)
                                mapItem.name = selectedPlacemark.name
                                mapItem.openInMaps()
                            }
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        Button("Show Route", systemImage: "location.north") {
                            showRoute.toggle()
                        }
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    .buttonStyle(.bordered)
                }
            }
            Spacer()
        }
        .padding()
        .task(id: selectedPlacemark) {
            await fetchLookaroundPreview()
        }
        .onAppear {
            if let selectedPlacemark, destination != nil {
                name = selectedPlacemark.name
                address = selectedPlacemark.address
            }
        }
    }
    func fetchLookaroundPreview() async {
        if let selectedPlacemark {
            lookaroundScene = nil
            let lookaroundRequest = MKLookAroundSceneRequest(coordinate: selectedPlacemark.coordinate)
            lookaroundScene = try? await lookaroundRequest.scene
        }
    }
}

#Preview("Destination Tab") {
    let container = Destination.preview
    let fetchDescriptor = FetchDescriptor<Destination>()
    let destination = try! container.mainContext.fetch(fetchDescriptor)[0]
    let selectedPlacemark = destination.placemarks[0]
    return LocationDetailView(
        destination: destination,
        selectedPlacemark: selectedPlacemark,
        showRoute: .constant(false),
        travelInterval: .constant(nil),
        transportType: .constant(.automobile)
    )
}

#Preview("TripMap Tab") {
    let container = Destination.preview
    let fetchDescriptor = FetchDescriptor<MTPlacemark>()
    let placemarks = try! container.mainContext.fetch(fetchDescriptor)
    let selectedPlacemark = placemarks[0]
    return LocationDetailView(
        selectedPlacemark: selectedPlacemark,
        showRoute: .constant(false),
        travelInterval: .constant(TimeInterval(1000)),
        transportType: .constant(.automobile)
    )
}
