import { describe, test, expect } from "bun:test";
import { runCLI, parseJSON } from "./helpers";

interface SearchResult {
  meta: { count: number; page: number };
  results: Array<{
    id: string;
    title: string;
    company: string | null;
    location: string | null;
    date: string | null;
    url: string;
  }>;
}

function parsedStderr(stderr: string): { error?: string; code?: string } {
  try {
    return JSON.parse(stderr);
  } catch {
    return {};
  }
}

describe("indeed-india CLI live smoke", () => {
  test("search returns at least one complete result", async () => {
    const result = await runCLI(["search", "-q", "accountant", "-l", "Chennai", "--limit", "5"]);
    const data = parseJSON<SearchResult>(result);
    expect(data.results.length).toBeGreaterThan(0);
    const first = data.results[0];
    expect(first.id).toBeTruthy();
    expect(first.title).toBeTruthy();
    expect(first.url).toContain("in.indeed.com/viewjob");
  }, 30000);

  test("detail of the first search result is readable", async () => {
    const search = await runCLI(["search", "-q", "accountant", "-l", "Chennai", "--limit", "1"]);
    const data = parseJSON<SearchResult>(search);
    const id = data.results[0].id;
    const detail = await runCLI(["detail", id]);
    const job = parseJSON<{ description: string | null; title: string }>(detail);
    expect(job.title).toBeTruthy();
    expect(job.description && job.description.length).toBeGreaterThan(20);
  }, 30000);
});

describe("indeed-india CLI flag validation", () => {
  test("search with no query and no location exits 1 with NO_CRITERIA", async () => {
    const result = await runCLI(["search"]);
    expect(result.exitCode).not.toBe(0);
    expect(parsedStderr(result.stderr).code).toBe("NO_CRITERIA");
  });

  test("non-numeric --jobage exits 1 with BAD_ARG", async () => {
    const result = await runCLI(["search", "-q", "accountant", "--jobage", "foo"]);
    expect(result.exitCode).not.toBe(0);
    const err = parsedStderr(result.stderr);
    expect(err.code).toBe("BAD_ARG");
    expect(err.error).toMatch(/jobage/);
  });

  test("non-numeric --limit exits 1 with BAD_ARG", async () => {
    const result = await runCLI(["search", "-q", "accountant", "--limit", "xyz"]);
    expect(result.exitCode).not.toBe(0);
    expect(parsedStderr(result.stderr).code).toBe("BAD_ARG");
  });

  test("detail with no id exits 1 with NO_ID", async () => {
    const result = await runCLI(["detail"]);
    expect(result.exitCode).not.toBe(0);
    expect(parsedStderr(result.stderr).code).toBe("NO_ID");
  });

  test("detail with unparseable id exits 1 with BAD_ID", async () => {
    const result = await runCLI(["detail", "not-a-key"]);
    expect(result.exitCode).not.toBe(0);
    expect(parsedStderr(result.stderr).code).toBe("BAD_ID");
  });
});
