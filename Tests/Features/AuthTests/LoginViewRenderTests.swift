import AuthFeature
import SharedKernel
import Testing

@MainActor
@Suite("LoginViewRender")
struct LoginViewRenderTests {
    @Test("Login screen renders the default state")
    func rendersDefaultState() throws {
        let tracked = makeLoginViewRenderSUT(mode: .success(makeLoginViewRenderSession()))
        defer { tracked.assertNoLeaks() }
        let context = tracked.context

        let data = try renderedPNG(from: LoginView(viewModel: context.viewModel))

        #expect(data.count > 1_000)
    }

    @Test("Login screen renders quick access and error feedback")
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

    @Test("Login screen renders the loading state while authentication is suspended")
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
