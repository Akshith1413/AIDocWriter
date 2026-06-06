# Aureview AI Deployment Guide: Backend on Render & Frontend on Vercel

This guide outlines the step-by-step process to deploy the **Aureview AI** backend API to Render and the React frontend to Vercel.

---

## Part 1: Deploying the Backend on Render

Render's free tier has an ephemeral disk, meaning local SQLite database files will be erased whenever the instance restarts or redeploys. To avoid losing users and documents, we will use a Render PostgreSQL database.

### Step 1: Create a PostgreSQL Database on Render
1. Log in to the [Render Dashboard](https://dashboard.render.com).
2. Click **New** (top right) and select **PostgreSQL**.
3. Fill out the details:
   - **Name**: `aureview-db`
   - **Database**: `aureview`
   - **User**: `aureview_user`
   - **Region**: Choose the region closest to you.
   - **Instance Type**: Select **Free** (or your preferred tier).
4. Click **Create Database**.
5. Once created, copy the **Internal Database URL** (for Render-to-Render communication) or **External Database URL** (for external setup/testing).

### Step 2: Deploy the FastAPI Backend
1. In the Render Dashboard, click **New** and select **Web Service**.
2. Connect your Git repository (GitHub/GitLab).
3. Set up the service details:
   - **Name**: `aureview-backend`
   - **Region**: Same region as your database.
   - **Root Directory**: `backend` (Important: points to the `backend/` subfolder).
   - **Language/Runtime**: `Python`
   - **Build Command**: `pip install .`
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - **Instance Type**: Select **Free** (or your preferred tier).
4. Click **Advanced** to add environment variables.

### Step 3: Configure Backend Environment Variables
Add the following key-value pairs under **Environment Variables** in Render:

| Key | Value | Description |
| :--- | :--- | :--- |
| `DATABASE_URL` | *[Your PostgreSQL Database URL]* | Set this to the PostgreSQL URL copied in Step 1. |
| `APP_ENV` | `production` | Set environment mode to production. |
| `SECRET_KEY` | *[Generate a long random string]* | Key used to sign JWT tokens (e.g. `openssl rand -hex 32`). |
| `GROQ_API_KEY` | `gsk_XPsyk...` | Your Groq API key. |
| `DEFAULT_PROVIDER` | `groq` | Set default LLM provider. |
| `DEFAULT_MODEL` | `llama-3.3-70b-versatile` | Set default LLM model. |
| `CORS_ORIGINS` | `https://your-frontend.vercel.app` | **CRITICAL**: The URL of your Vercel deployment (we will update this once Vercel is set up). |

5. Click **Create Web Service**. Render will build the environment and start the Uvicorn server.

---

## Part 2: Deploying the Frontend on Vercel

Vercel detects Vite applications automatically. We will configure it to build the React app and point it to the Render backend URL.

### Step 1: Push Frontend Code to Vercel
1. Log in to [Vercel](https://vercel.com).
2. Click **Add New** -> **Project**.
3. Import your Git repository.
4. Set up the project details:
   - **Framework Preset**: `Vite` (Vercel should automatically detect this).
   - **Root Directory**: `frontend` (Important: points to the `frontend/` subfolder).
5. Open the **Environment Variables** dropdown.

### Step 2: Configure Environment Variables
Add the following variable:

- **Key**: `VITE_API_URL`
- **Value**: `https://your-backend-service.onrender.com/api` (Replace this with the live URL Render gives you for your backend web service, appending `/api` at the end).

### Step 3: Deploy
1. Click **Deploy**.
2. Once the build finishes, copy the deployment URL (e.g. `https://aureview-frontend.vercel.app`).

---

## Part 3: Link CORS Settings

After getting your Vercel frontend URL:
1. Go back to the [Render Dashboard](https://dashboard.render.com).
2. Open your `aureview-backend` Web Service.
3. Navigate to the **Environment** tab.
4. Update `CORS_ORIGINS` with your Vercel URL (e.g., `https://aureview-frontend.vercel.app`).
5. Save changes. Render will automatically redeploy the backend with the new CORS permissions.
