// FeedBuilderTests.swift
// Tests del orden/mezcla del feed. La función real es privada en HomeView,
// así que aquí reproducimos los algoritmos para garantizar invariantes.
import XCTest
@testable import Erasmus_App

final class FeedBuilderTests: XCTestCase {

    // MARK: - Shuffle determinístico con seed
    func test_lcg_shuffle_is_deterministic_for_same_seed() {
        let a = lcgShuffle([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], seed: 42)
        let b = lcgShuffle([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], seed: 42)
        XCTAssertEqual(a, b, "Mismo seed debe producir mismo orden")
    }

    func test_lcg_shuffle_different_seeds_produce_different_orders() {
        let a = lcgShuffle([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], seed: 42)
        let b = lcgShuffle([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], seed: 99)
        XCTAssertNotEqual(a, b, "Seeds distintos deben generar ordenaciones distintas")
    }

    func test_shuffle_preserves_elements() {
        let original = Array(1...20)
        let shuffled = lcgShuffle(original, seed: 1234)
        XCTAssertEqual(shuffled.sorted(), original, "Shuffle no debe perder ni añadir elementos")
    }

    func test_shuffle_handles_single_element() {
        XCTAssertEqual(lcgShuffle([42], seed: 1), [42])
    }

    func test_shuffle_handles_empty() {
        XCTAssertEqual(lcgShuffle([Int](), seed: 1), [])
    }

    // MARK: - Reproducción privada del algoritmo (Fisher-Yates con LCG)
    private func lcgShuffle<T>(_ input: [T], seed: Int) -> [T] {
        var all = input
        guard all.count > 1 else { return all }
        var rng = UInt(bitPattern: seed == 0 ? 12345 : seed)
        for i in stride(from: all.count - 1, through: 1, by: -1) {
            rng = rng &* 6364136223846793005 &+ 1442695040888963407
            let j = Int(rng >> 33) % (i + 1)
            all.swapAt(i, j)
        }
        return all
    }
}
