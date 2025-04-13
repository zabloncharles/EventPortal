//
//  GroupCreationFlow.swift
//  EventAppPortal
//
//  Created by Zablon Charles on 4/12/25.
//

import SwiftUI
import CoreLocation
// MARK: - Group Creation Flow

struct GroupCreationFlow: View {
    @ObservedObject var viewModel: CreateGroupViewModel
    @State private var currentStep = 0
    let steps = ["Basic Info", "Details", "Preview"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress Steps
            ProgressStepsView(steps: steps, currentStep: currentStep)
                .padding(.horizontal) .padding(.horizontal)
            
            // Content
            TabView(selection: $currentStep) {
                // MARK: - Page 1: Basic Info
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Group Icon
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue, .purple]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: categoryIcon(for: viewModel.category))
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Group Icon")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        // Category Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.categories, id: \.self) { category in
                                        Button(action: { viewModel.category = category }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: categoryIcon(for: category))
                                                    .font(.system(size: 14))
                                                Text(category)
                                                    .font(.subheadline)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(viewModel.category == category ? Color.blue : Color.gray.opacity(0.1))
                                            .foregroundColor(viewModel.category == category ? .white : .primary)
                                            .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }.padding(.horizontal)
                        // Basic Info Section
                        FormSection {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Basic Information")
                                    .font(.headline)
                                    .padding(.bottom, 8)
                                
                                CustomTextField(
                                    title: "Group Name",
                                    placeholder: "Give your group a name",
                                    text: $viewModel.name
                                )
                                
                                CustomTextField(
                                    title: "Description",
                                    placeholder: "Describe your group",
                                    text: $viewModel.description,
                                    isMultiline: true
                                )
                                
                                
                            }
                        }
                        
                        // Next Button
                        ActionButton(title: "Next", gradient: [.blue, .purple]) {
                            withAnimation {
                                currentStep = 1
                            }
                        }
                    }
                    .padding()
                }
                .tag(0)
                
                // MARK: - Page 2: Details
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Privacy Settings
                        FormSection {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Privacy Settings")
                                    .font(.headline)
                                    .padding(.bottom, 8)
                                
                                Toggle(isOn: $viewModel.isPrivate) {
                                    HStack {
                                        Image(systemName: viewModel.isPrivate ? "lock.fill" : "globe")
                                            .foregroundColor(viewModel.isPrivate ? .blue : .gray)
                                        VStack(alignment: .leading) {
                                            Text(viewModel.isPrivate ? "Private Group" : "Public Group")
                                                .font(.subheadline)
                                            Text(viewModel.isPrivate ? "Only invited people can join" : "Anyone can discover and join")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Navigation Buttons
                        HStack(spacing: 16) {
                            ActionButton(title: "Back", gradient: [.gray, .gray]) {
                                withAnimation {
                                    currentStep = 0
                                }
                            }
                            
                            ActionButton(title: "Preview", gradient: [.blue, .purple]) {
                                withAnimation {
                                    currentStep = 2
                                }
                            }
                        }
                    }
                    .padding()
                }
                .tag(1)
                
                // MARK: - Page 3: Preview
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Group Preview using GroupCard
                        GroupCard(
                            group: EventGroup(
                                id: "preview",
                                name: viewModel.name.isEmpty ? "Group Name" : viewModel.name,
                                description: viewModel.description,
                                shortDescription: viewModel.description.isEmpty ? "No description provided" : String(viewModel.description.prefix(50)) + "...",
                                memberCount: 1,
                                imageURL: "",
                                location: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                createdAt: Date(),
                                createdBy: "preview",
                                isPrivate: viewModel.isPrivate,
                                category: viewModel.category,
                                tags: [],
                                pendingRequests: [],
                                members: [],
                                admins: []
                            )
                        )
                        .padding(.horizontal)
                        Spacer()
                        // Navigation Buttons
                        VStack(spacing: 16) {
                            ActionButton(title: "Create Group", gradient: [.purple, .blue]) {
                                viewModel.createGroup()
                            }
                            
                            Button(action: {
                                withAnimation {
                                    currentStep = 1
                                }
                            }) {
                                Text("Edit Details")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
        }
        .navigationTitle(steps[currentStep])
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Helper function to get the appropriate icon for each category
    func categoryIcon(for category: String) -> String {
        switch category {
            case "Technology":
                return "desktopcomputer"
            case "Sports":
                return "figure.dance"
            case "Art & Culture":
                return "paintbrush.fill"
            case "Music":
                return "music.note.list"
            case "Food":
                return "fork.knife"
            case "Travel":
                return "airplane"
            case "Environmental":
                return "leaf.arrow.triangle.circlepath"
            case "Literature":
                return "book.fill"
            case "Corporate":
                return "building.2.fill"
            case "Health & Wellness":
                return "heart.fill"
            case "Other":
                return "ellipsis.circle.fill"
            default:
                return "person.3.fill"
        }
    }
}


