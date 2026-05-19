#!/usr/bin/env node
// One-off script: bulk-uploads seed images to UploadThing and prints a JSON map of filename → URL.
// Usage: node scripts/upload-seed-images.js
// Requires UPLOADTHING_TOKEN in backend/.env (loaded automatically below).

import { readFileSync, readdirSync, writeFileSync } from 'fs'
import { join, basename, extname } from 'path'
import { UTApi, UTFile } from 'uploadthing/server'

const IMAGES_ROOT = new URL('../swaptunes-images', import.meta.url).pathname
const OUTPUT_FILE = new URL('../swaptunes-images/uploaded-urls.json', import.meta.url).pathname

const FOLDERS = ['profile-images', 'post-images', 'playlist-cover']
const MIME = { '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png', '.webp': 'image/webp' }

const utapi = new UTApi()

function collectFiles() {
  const files = []
  for (const folder of FOLDERS) {
    const dir = join(IMAGES_ROOT, folder)
    for (const name of readdirSync(dir)) {
      const ext = extname(name).toLowerCase()
      if (!MIME[ext]) continue
      files.push({ folder, name, path: join(dir, name) })
    }
  }
  return files
}

async function uploadBatch(batch) {
  const utFiles = batch.map(({ name, path }) =>
    new UTFile([readFileSync(path)], name, { type: MIME[extname(name).toLowerCase()] })
  )
  const results = await utapi.uploadFiles(utFiles)
  return results
}

async function main() {
  const allFiles = collectFiles()
  console.log(`Found ${allFiles.length} images across ${FOLDERS.length} folders. Uploading…\n`)

  const output = {}
  const BATCH_SIZE = 10

  for (let i = 0; i < allFiles.length; i += BATCH_SIZE) {
    const batch = allFiles.slice(i, i + BATCH_SIZE)
    console.log(`Uploading batch ${Math.floor(i / BATCH_SIZE) + 1} (${batch.map(f => f.name).join(', ')})`)

    const results = await uploadBatch(batch)

    for (let j = 0; j < batch.length; j++) {
      const { folder, name } = batch[j]
      const res = results[j]
      if (res.error) {
        console.error(`  FAILED: ${name} — ${res.error.message}`)
      } else {
        const key = `${folder}/${name}`
        output[key] = res.data.url
        console.log(`  OK: ${key} → ${res.data.url}`)
      }
    }
  }

  writeFileSync(OUTPUT_FILE, JSON.stringify(output, null, 2))
  console.log(`\nDone! URLs saved to swaptunes-images/uploaded-urls.json`)
}

main().catch(err => { console.error(err); process.exit(1) })
