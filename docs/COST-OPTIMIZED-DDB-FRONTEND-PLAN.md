# Cost-Optimized DynamoDB + Frontend Rollout Plan

Date: 2026-04-02

## Objectives

1. Upload adoption metadata without breaking existing team/vendor schema.
2. Reduce DynamoDB read cost for high-traffic list endpoints.
3. Expose adoption metadata in frontend with minimal payload overhead.
4. Keep backward compatibility during migration.

## Agreed Architecture

### Data Layer

- Keep primary TEAM and VENDOR metadata items.
- Add adoption metadata into TEAM metadata as `PartnershipMetadata` map.
- Create two precomputed list records:
  - `PK=LIST#TEAM, SK=ALL` containing `Teams` summaries.
  - `PK=LIST#VENDOR, SK=ALL` containing `Vendors` summaries.

Why this is cost-optimized:
- `/teams` and `/vendors` become one `GetItem` each instead of full-table `Scan`.
- Team detail remains single `GetItem` (`TEAM#{teamId}`, `METADATA`).

### API Layer

- `GET /teams` reads `LIST#TEAM/ALL` (fallback to scan if missing).
- `GET /vendors` reads `LIST#VENDOR/ALL` (fallback to scan if missing).
- Existing `GET /teams/{teamId}` unchanged and used for detailed modal data.

### Frontend Layer

- Teams page first loads lightweight list summaries.
- Team modal lazily fetches `GET /teams/{teamId}` on demand.
- Modal renders adoption metadata when available:
  - start year
  - confidence
  - source link

## Execution Checklist

- [x] Upload script merges `adoption_metadata_patch.json` updates into team records.
- [x] Upload script generates and uploads `LIST#TEAM` and `LIST#VENDOR` records.
- [x] Teams API switched to list-record reads with scan fallback.
- [x] Vendors API switched to list-record reads with scan fallback.
- [x] Teams frontend modal changed to lazy detail fetch.
- [x] Teams frontend displays partnership adoption metadata when present.

## Cost and Performance Notes

- Read pattern shift:
  - Before: `Scan` for list endpoints.
  - After: `GetItem` for list endpoints.
- Table billing mode is already `PAY_PER_REQUEST`, which is appropriate for variable workload.
- This pattern avoids immediate Terraform/index changes and still yields significant read-cost reduction.

## Rollout Steps

1. Run upload:

```bash
python upload_to_dynamodb.py --sync
```

2. Verify records exist:
- `LIST#TEAM / ALL`
- `LIST#VENDOR / ALL`
- Sample team has `PartnershipMetadata` in `TEAM#{id} / METADATA`.

3. Deploy backend Lambdas.

4. Deploy frontend static assets.

5. Smoke tests:
- `GET /teams` returns list.
- `GET /teams/{id}` returns `PartnershipMetadata` for patched teams.
- Teams modal shows adoption info and source links.

## Next Optimization (Optional)

1. Add response cache headers + CloudFront caching for list endpoints.
2. Add `LastUpdated` to list records and frontend stale-data badge.
3. Add dedicated endpoint `/teams/{id}/partnerships` if item size grows.
