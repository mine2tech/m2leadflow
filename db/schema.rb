# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_20_194453) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "apollo_accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "credentials_encrypted"
    t.integer "credits_remaining", default: 0
    t.string "email", null: false
    t.date "reset_date"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_apollo_accounts_on_email", unique: true
    t.index ["status"], name: "index_apollo_accounts_on_status"
  end

  create_table "companies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "domain", null: false
    t.string "name", null: false
    t.text "notes"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_companies_on_domain", unique: true
    t.index ["status"], name: "index_companies_on_status"
  end

  create_table "contacts", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.float "confidence_score"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name"
    t.string "role"
    t.string "source"
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_contacts_on_company_id"
    t.index ["email"], name: "index_contacts_on_email", unique: true
  end

  create_table "drafts", force: :cascade do |t|
    t.text "body"
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.bigint "email_thread_id"
    t.integer "sequence_number"
    t.integer "status", default: 0, null: false
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["contact_id", "sequence_number"], name: "index_drafts_on_contact_id_and_sequence"
    t.index ["contact_id", "status"], name: "index_drafts_on_contact_id_and_status"
    t.index ["contact_id"], name: "index_drafts_on_contact_id"
    t.index ["email_thread_id"], name: "index_drafts_on_email_thread_id"
    t.index ["status"], name: "index_drafts_on_status"
  end

  create_table "email_threads", force: :cascade do |t|
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.string "external_thread_id"
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_email_threads_on_contact_id"
    t.index ["external_thread_id"], name: "index_email_threads_on_external_thread_id"
  end

  create_table "followups", force: :cascade do |t|
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.integer "delay_days"
    t.bigint "draft_id"
    t.datetime "scheduled_at"
    t.integer "sequence_number"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id", "sequence_number", "status"], name: "index_followups_on_contact_seq_status"
    t.index ["contact_id"], name: "index_followups_on_contact_id"
    t.index ["draft_id"], name: "index_followups_on_draft_id"
    t.index ["scheduled_at"], name: "index_followups_on_scheduled_at"
    t.index ["status"], name: "index_followups_on_status"
  end

  create_table "gmail_accounts", force: :cascade do |t|
    t.text "access_token_ciphertext"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.text "refresh_token_ciphertext"
    t.integer "status", default: 0, null: false
    t.datetime "token_expires_at"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_gmail_accounts_on_email", unique: true
  end

  create_table "meetings", force: :cascade do |t|
    t.bigint "contact_id", null: false
    t.datetime "created_at", null: false
    t.string "meeting_link"
    t.text "notes"
    t.datetime "scheduled_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id", "status"], name: "index_meetings_on_contact_id_and_status"
    t.index ["contact_id"], name: "index_meetings_on_contact_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "direction", null: false
    t.bigint "email_thread_id", null: false
    t.string "gmail_message_id"
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["direction"], name: "index_messages_on_direction"
    t.index ["email_thread_id"], name: "index_messages_on_email_thread_id"
    t.index ["gmail_message_id"], name: "index_messages_on_gmail_message_id"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "tasks", force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "error"
    t.integer "max_attempts", default: 3, null: false
    t.jsonb "payload", default: {}
    t.jsonb "result", default: {}
    t.integer "status", default: 0, null: false
    t.string "task_type", null: false
    t.datetime "updated_at", null: false
    t.index ["status", "created_at"], name: "index_tasks_on_status_and_created_at"
    t.index ["status"], name: "index_tasks_on_status"
    t.index ["task_type"], name: "index_tasks_on_task_type"
  end

  add_foreign_key "contacts", "companies"
  add_foreign_key "drafts", "contacts"
  add_foreign_key "drafts", "email_threads"
  add_foreign_key "email_threads", "contacts"
  add_foreign_key "followups", "contacts"
  add_foreign_key "followups", "drafts"
  add_foreign_key "meetings", "contacts"
  add_foreign_key "messages", "email_threads"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
