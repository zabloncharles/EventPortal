//
//  EventCreationFlow.swift
//  EventAppPortal
//
//  Created by Zablon Charles on 4/12/25.
//

import SwiftUI

// MARK: - Event Creation Flow

struct EventCreationFlow: View {
    @ObservedObject var viewModel: CreateEventViewModel
    @State private var currentStep = 0
    let steps = ["Basic Info", "Date & Time", "Location & Details", "Preview"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress Steps
            ProgressStepsView(steps: steps, currentStep: currentStep)
                .padding(.horizontal) .padding(.horizontal)
            
            // Content
            TabView(selection: $currentStep) {
                BasicInfoView(viewModel: viewModel) {
                    withAnimation {
                        currentStep = 1
                    }
                }
                .tag(0)
                
                DateTimeView(viewModel: viewModel,
                             onBack: {
                    withAnimation {
                        currentStep = 0
                    }
                },
                             onNext: {
                    withAnimation {
                        currentStep = 2
                    }
                })
                .tag(1)
                
                LocationDetailsView(viewModel: viewModel,
                                    onBack: {
                    withAnimation {
                        currentStep = 1
                    }
                },
                                    onNext: {
                    withAnimation {
                        currentStep = 3
                    }
                })
                .tag(2)
                
                PreviewView(viewModel: viewModel,
                            onBack: {
                    withAnimation {
                        currentStep = 2
                    }
                },
                            onCreateEvent: {
                    viewModel.createEvent()
                })
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
        }
        .navigationTitle(steps[currentStep])
        .navigationBarTitleDisplayMode(.inline)
    }
}


