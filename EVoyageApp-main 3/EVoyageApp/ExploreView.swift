//
//  ExploreView.swift
//  EVoyageApp
//
//  Created by Furkan Erdoğan on 26.05.2024.
//

import SwiftUI
import MapKit
import Firebase

struct ExploreView: View {
    @State var travels: [TravelDBModel] = []
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.blue.ignoresSafeArea()
                VStack {
                    ScrollView {
                        LazyVStack {
                            ForEach(travels, id: \.id) { travel in
                                RowView(travel: travel)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Explore")
            .task {
                do {
                    guard let user = try? await CurrentUserInfoService.shared.getCurrentUser() else { return }
                    let travels = try await fetchTravels(for: user)
                    self.travels = travels
                } catch {
                    print("Hata var")
                }
            }
        }
    }
    
    private func fetchTravels(for currentUser: UserDB) async throws -> [TravelDBModel] {
        let excludedUserUids = [currentUser.userUid]
        return try await db.collection("Travels")
            .whereField("user.uid", notIn: excludedUserUids)
            .getDocuments()
            .documents
            .compactMap { try? $0.data(as: TravelDBModel.self) }
            .sorted { $0.publishedDate > $1.publishedDate }
    }
}

struct RowView: View {
    let travel: TravelDBModel
    
    var body: some View {
        VStack(alignment: .leading) {
            MapView(coordinate1: CLLocationCoordinate2D(latitude: travel.departure.coordinates.latitude, longitude: travel.departure.coordinates.longitude), coordinate2: CLLocationCoordinate2D(latitude: travel.arrival.coordinates.latitude, longitude: travel.arrival.coordinates.longitude))
                .frame(height: 200)
            
            HStack {
                Text(travel.user.nameSurname)
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
                Text(travel.departureDate.formattedAsDDMMYYYY)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.all, 10)
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

struct MapView: UIViewRepresentable {
    var coordinate1: CLLocationCoordinate2D
    var coordinate2: CLLocationCoordinate2D
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (coordinate1.latitude + coordinate2.latitude) / 2,
                longitude: (coordinate1.longitude + coordinate2.longitude) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: abs(coordinate1.latitude - coordinate2.latitude) * 2,
                longitudeDelta: abs(coordinate1.longitude - coordinate2.longitude) * 2
            )
        )
        
        uiView.setRegion(region, animated: true)
        
        let annotation1 = MKPointAnnotation()
        annotation1.coordinate = coordinate1
        
        let annotation2 = MKPointAnnotation()
        annotation2.coordinate = coordinate2
        
        uiView.addAnnotations([annotation1, annotation2])
        
        let polyline = MKPolyline(coordinates: [coordinate1, coordinate2], count: 2)
        uiView.addOverlay(polyline)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
    }
}

