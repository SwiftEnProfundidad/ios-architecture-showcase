import AuthFeature
import SharedKernel
import Testing

@MainActor
@Suite("LoginViewRender")
struct LoginViewRenderTests {
    @Test("Given the default login state, when the login screen is rendered, then the default UI is shown")
    func rendersDefaultState() throws {
        let tracked = makeLoginViewRenderSUT(mode: .success(makeLoginViewRenderSession()))
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        let data = try renderedPNG(from: LoginView(viewModel: context.viewModel))

        #expect(data.count > 1_000)
    }

    @Test("Given quick access and an authentication error, when the login screen is rendered, then both are visible")
    func rendersQuickAccessAndErrorState() async throws {
        let tracked = makeLoginViewRenderSUT(
            mode: .invalidCredentials,
            quickAccessEmail: ShowcaseLoginFixtures.email,
            quickAccessPassword: ShowcaseLoginFixtures.password
        )
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        await context.viewModel.login()
        let data = try renderedPNG(
            from: LoginView(viewModel: context.viewModel),
            colorScheme: .dark
        )

        #expect(context.viewModel.errorMessage == AppStrings.localized("auth.error.invalidCredentials"))
        #expect(data.count > 1_000)
    }

    @Test("Given authentication is in progress, when the login screen is rendered, then the loading state is shown")
    func rendersLoadingState() async throws {
        let tracked = makeLoginViewRenderSUT(mode: .suspended(makeLoginViewRenderSession()))
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        let task = Task {
            await context.viewModel.login()
        }
        await Task.yield()

        let data = try renderedPNG(from: LoginView(viewModel: context.viewModel))

        #expect(context.viewModel.isLoading)
        #expect(data.count > 1_000)

        await context.executor.resume()
        await task.value
    }
}
