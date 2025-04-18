//
//  GroupDetailView.swift
//  EventAppPortal
//
//  Created by Zablon Charles on 4/18/25.
//

import SwiftUI
import FirebaseFirestore

struct GroupDetailView: View {
    let group: EventGroup
    @Environment(\.presentationMode) var presentationMode
    @State private var showJoinAlert = false
    @State private var scrollOffset: CGFloat = 0
    let colors = [Color.red, Color.blue, Color.green, Color.purple, Color.orange]
    @StateObject private var tabBarManager = TabBarVisibilityManager.shared
    @State private var isDescriptionExpanded = false
    @State private var pageAppeared = false
    @State private var bottomBarAppeared = false
    @State private var currentPage = 0
    @State private var memberCount: Int = 0
    @State private var randomColor = Color.randomizetextcolor
    @State private var randomColor2 = Color.randomizetextcolor
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var isMember = false
    @State private var adminName: String = ""
    @State private var memberNames: [String: String] = [:]
    
    // MARK: - Helper Functions
    private func categoryIcon(for category: String) -> String {
        switch category {
            case "Sports": return "figure.run"
            case "Music": return "music.note"
            case "Art": return "paintbrush.fill"
            case "Technology": return "desktopcomputer"
            case "Food": return "fork.knife"
            case "Travel": return "airplane"
            case "Environmental": return "leaf.arrow.triangle.circlepath"
            case "Literature": return "book.fill"
            case "Corporate": return "building.2.fill"
            case "Health & Wellness": return "heart.fill"
            default: return "star.fill"
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        ZStack(alignment: .top) {
            
            
            VStack {
                Spacer()
                
                
                Spacer()
                HStack {
                    Spacer()
                    Image("smilepov")
                        .resizable()
                        .renderingMode(.original)
                        .aspectRatio(contentMode: .fit)
                        .frame(width:200,height:200)
                        .background( Circle().fill(Color.clear).background(LinearGradient(
                            gradient: Gradient(colors: [randomColor2, Color.clear, randomColor.opacity(0.30)]),
                            startPoint: .bottom,
                            endPoint: .center
                        )).clipShape(Circle()))
                    Spacer()
                }
                
                .padding(.horizontal)
                .padding(.bottom, 50)
            }.scaleEffect(bottomBarAppeared ? 1 : 0.97)
                .animation(.spring(), value: bottomBarAppeared)
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                GroupTypeIcon(
                    icon: categoryIcon(for: group.category),
                    text: group.category
                )
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 40)
                GroupTypeIcon(
                    icon: "eye",
                    text: "\(group.memberCount) Views"
                )
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                GroupTypeIcon(
                    icon: "person.2",
                    text: "\(group.memberCount) Members"
                )
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                GroupTypeIcon(
                    icon: "mappin.circle",
                    text: "New York"
                )
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 40)
                
                GroupTypeIcon(
                    icon: group.isPrivate ? "lock.fill" : "lock.open.fill",
                    text: group.isPrivate ? "Private" : "Public"
                )
            }
        }
        .padding(.vertical)
        .background(Color.dynamic)
        .cornerRadius(16)
        .padding(.top, -15)
        .padding(.bottom, -20)
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.description)
                    .foregroundColor(.secondary)
                    .lineLimit(isDescriptionExpanded ? nil : 2)
                    .animation(.easeInOut, value: isDescriptionExpanded)
                
                Button(action: {
                    withAnimation {
                        isDescriptionExpanded.toggle()
                    }
                }) {
                    Text(isDescriptionExpanded ? "Read Less" : "Read More")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(randomColor2)
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Admin Section
    private var adminSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Group Admin")
                .font(.title3)
                .fontWeight(.bold)
            
            HStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [randomColor2, .blue]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(adminName.prefix(1).uppercased())
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading) {
                    Text(adminName)
                        .fontWeight(.semibold)
                    Text("Group Admin")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Text("Message")
                        .font(.subheadline.bold())
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Members Section
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Members")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button("See All") {
                    // Action
                }
                .foregroundColor(.blue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(group.members.prefix(6), id: \.self) { memberId in
                        VStack(spacing: 8) {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [colors.randomElement() ?? .blue, .blue]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text((memberNames[memberId] ?? "").prefix(1).uppercased())
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                )
                            
                            Text(memberNames[memberId] ?? "")
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Join Button Section
    private var joinButtonSection: some View {
        Group {
            if isMember {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Joined")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(20)
                    .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                    .padding()
                }
            } else {
                Button(action: { showJoinAlert = true }) {
                    Text("Join Group")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [randomColor, .blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        .padding()
                }
            }
        }
        .opacity(bottomBarAppeared ? 1 : 0)
        .offset(y: bottomBarAppeared ? 0 : 50)
    }
    
    var body: some View {
        ZStack {
            ScrollableNavigationBar(
                title: group.category,
                icon: "person.3.fill",
                isInline: true,
                showBackButton: true
            ) {
                VStack(spacing: 0) {
                    headerSection
                        .frame(height: 400)
                    
                    VStack(alignment: .leading, spacing: 24) {
                        // Title and Stats
                        VStack {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(group.name)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.invert, randomColor],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    HStack {
                                        Text("New York City")
                                        Image(systemName: "location")
                                    }
                                    .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            
                            statsSection
                        }
                        
                        descriptionSection
                        adminSection
                        membersSection
                    }
                    .padding()
                    .offset(y: !pageAppeared ? UIScreen.main.bounds.height * 0.5 : 0)
                }.padding(.bottom, 140)
            }
            
            VStack {
                Spacer()
                joinButtonSection
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                pageAppeared = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    bottomBarAppeared = true
                }
            }
            tabBarManager.hideTab = true
            checkMembershipStatus()
            fetchUserNames()
        }
        .onDisappear {
            tabBarManager.hideTab = false
        }
        .alert("Join Group", isPresented: $showJoinAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Join") {
                joinGroup()
            }
        } message: {
            Text("Would you like to join \(group.name)?")
        }
    }
    
    private func checkMembershipStatus() {
        guard let userId = firebaseManager.currentUser?.uid else { return }
        isMember = group.members.contains(userId)
    }
    
    private func joinGroup() {
        guard let userId = firebaseManager.currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(group.id)
        
        groupRef.updateData([
            "members": FieldValue.arrayUnion([userId])
        ]) { error in
            if let error = error {
                print("Error joining group: \(error)")
            } else {
                isMember = true
            }
        }
    }
    
    private func fetchUserNames() {
        let db = Firestore.firestore()
        
        // Fetch admin name
        db.collection("users").document(group.createdBy).getDocument { document, error in
            if let document = document, document.exists,
               let userData = document.data(),
               let fullName = userData["name"] as? String {
                adminName = String(fullName.split(separator: " ").first ?? "")
            }
        }
        
        // Fetch member names
        for memberId in group.members {
            db.collection("users").document(memberId).getDocument { document, error in
                if let document = document, document.exists,
                   let userData = document.data(),
                   let fullName = userData["name"] as? String {
                    memberNames[memberId] = String(fullName.split(separator: " ").first ?? "")
                }
            }
        }
    }
}
